Class CGooglePlugin extends CAccessorPlugin
{
    ;Register this plugin with the Accessor main object
    static Type := CAccessor.RegisterPlugin("Google", CGooglePlugin)

    Description := "Quickly access google by typing ""[keyword] Search query"" and open the results `ndirectly from within Accessor."

    Cleared := false
    List := Array()

    AllowDelayedExecution := false

    Column2Text := "URL"

    Class CSettings extends CAccessorPlugin.CSettings
    {
        Keyword := "g"
        KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
        MinChars := 0
    }

    Class CResult extends CAccessorPlugin.CResult
    {
        Class CActions extends CArray
        {
            DefaultAction := new CAccessor.CAction("Open URL", "OpenURL")
            __new()
            {
                this.Insert(new CAccessor.CAction("Copy URL`tCTRL + C", "Copy", "", false, false))
                this.Insert(CAccessorPlugin.CActions.OpenWith)
            }
        }
        Type := "Google"
        Actions := new this.CActions()
        Priority := CGooglePlugin.Instance.Priority
        MatchQuality := 1 ;Only direct matches are used by this plugin
        Detail1 := "Google result"
    }

    IsInSinglePluginContext(Filter, LastFilter)
    {
        if(InStr(Filter, this.Settings.Keyword " ") = 1)
        {
            if(!this.Cleared)
            {
                this.Cleared := true
                CAccessor.Instance.RefreshList()
            }
            return true
        }
        this.Cleared := false
        return false
    }

    OnOpen(Accessor)
    {
        this.List := Array()
        this.Cleared := false
    }

    RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
    {
        if(!KeywordSet)
            return
        Results := Array()
        for index, ListEntry in this.List
        {
            Result := new this.CResult()
            Result.Title := ListEntry.titleNoFormatting
            Result.VisibleURL := ListEntry.VisibleURL
            Result.Path := ListEntry.UnescapedUrl
            Result.Icon := Accessor.GenericIcons.URL
            Results.Insert(Result)
        }
        return Results
    }

    GetDisplayStrings(ListEntry, ByRef Title, ByRef Path, ByRef Detail1, ByRef Detail2)
    {
        Path := ListEntry.VisibleURL
    }
    OpenURL(Accessor, ListEntry)
    {
        Run(ListEntry.Path)
    }

    Copy(Accessor, ListEntry)
    {
        Clipboard := ListEntry.Path
    }

    OnFilterChanged(ListEntry, Filter, LastFilter)
    {
        SetTimer, QueryGoogleResult, -100
        return false
    }

}

;This function is not moved into the class because it seems possible that AHK can hang up when this function is called via SetTimerF().
QueryGoogleResult:
QueryGoogleResult()
return
QueryGoogleResult()
{

    outputdebug query google result
    if(InStr(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ") != 1)
        return
    outputdebug do it
    Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ")
    ApiUri := "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=" uriEncode(Filter) "&rsz=8&key=ABQIAAAA7YzZ21dHSNKA2c0eu0LVKRTn4CuOUlhiyluSCHXJ1XXcqBr54RRnE69I0b16vHAVgBri6LxRQYtELw"

    Headers := "Referer: http://code.google.com/p/7plus/`n"
    Headers .= Settings.Connection.UseProxy && Settings.Connection.ProxyPassword ? "Proxy-Authorization: Basic " Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) : ""
    Options := Settings.Connection.UseProxy ? "Proxy: " Settings.Connection.ProxyAddress ":" Settings.Connection.ProxyPort : ""

    Debug("HTTPRequest request HEADER:", Headers)
    Debug("HTTPRequest request Options:", Options)

    HTTPRequest(ApiUri, GoogleQuery, Headers, Options)

    Debug("HTTPRequest response HEADER:", Headers)
    Debug("HTTPRequest response BODY:", GoogleQuery)

    CGooglePlugin.Instance.List := Array()

    results := Jxon_Load(GoogleQuery)
    for index, result in results.responseData.results
    {
        titleNoFormatting := unhtml(Deref_Umlauts(result.titleNoFormatting))
        CGooglePlugin.Instance.List.Insert(Object("unescapedURL",result.unescapedURL,"visibleUrl", result.visibleUrl, "titleNoFormatting", titleNoFormatting))
    }
    CAccessor.Instance.RefreshList()
}