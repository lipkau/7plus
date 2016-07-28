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
    static ApiToken := "AIzaSyD6DzFckD2ZVPAP9PWOKoG6IjLshQZDdHM"
    static CSEid    := "005570427367324167253:wrxcsmzl9a8"
    if(InStr(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ") != 1)
        return
    Debug("Accessor tigger:", "Google Plugin")
    Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, CGooglePlugin.Instance.Settings.Keyword " ")

    ApiURi := "https://www.googleapis.com/customsearch/v1?key=" ApiToken "&cx=" CSEid "&q=" uriEncode(Filter)

    Headers := "Referer: http://code.google.com/p/7plus/`n"
    ; if (Settings.Connection.UseProxy && Settings.Connection.ProxyUser)
        ; Headers .= "Proxy-Authorization: " (Settings.Connection.ProxyAuthType == 2 ? "NTLM " : "Basic ") Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) "`n"
    Headers .= Settings.Connection.UseProxy && Settings.Connection.ProxyPassword ? "Proxy-Authorization: Basic " Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) : ""

    Options := "Method: GET`n"
    Options .= "Charset: UTF-8`n"
    Options .= Settings.Connection.UseProxy ? "Proxy: " Settings.Connection.ProxyAddress ":" Settings.Connection.ProxyPort "`n" : ""

    Debug("HTTPRequest request HEADER:", Headers)
    Debug("HTTPRequest request Options:", Options)

    HTTPRequest(ApiURi, GETdata, Headers, Options)

    Debug("HTTPRequest response HEADER:", Headers)
    Debug("HTTPRequest response BODY:", GETdata)

    CGooglePlugin.Instance.List := Array()

    results := Jxon_Load(GETdata)

    for index, result in results.items
    {
        titleNoFormatting := unhtml(Deref_Umlauts(result.title))
        CGooglePlugin.Instance.List.Insert(Object("unescapedURL",result.link,"visibleUrl", result.displayLink, "titleNoFormatting", titleNoFormatting))
    }
    CAccessor.Instance.RefreshList()
}