Class CWeatherPlugin extends CAccessorPlugin
{
    ;Register this plugin with the Accessor main object
    static Type := CAccessor.RegisterPlugin("Weather", CWeatherPlugin)

    Description := "Quickly look at the weather for any location using Google. Just type ""[Keyword] location""."

    Cleared := false
    List := Array()

    AllowDelayedExecution := false

    Column1Text := "Weather Prediction"
    Column2Text := "Location"

    Class CSettings extends CAccessorPlugin.CSettings
    {
        Keyword := "Weather"
        KeywordOnly := false ;This is actually true, but IsInSinglePluginContext needs to be called every time so it is handled manually here
        MinChars := 2
        DefaultLocation := ""
    }

    Class CResult extends CAccessorPlugin.CResult
    {
        Class CActions extends CArray
        {
            DefaultAction := new CAccessor.CAction("Copy`tCTRL + C", "Copy", "", true, false)
            __new()
            {
            }
        }
        Type := "Weather"
        Actions := new this.CActions()
        Priority := CWeatherPlugin.Instance.Priority
        MatchQuality := 1 ; All results are equally good
    }

    IsInSinglePluginContext(Filter, LastFilter)
    {
        if(InStr(Filter, this.Settings.Keyword) = 1)
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

    OnGUICreate(AccessorGUI)
    {
        AccessorGUI.lnkFooter.Click.Handler := new Delegate(this, "OnFooterClick")
    }
    OnFooterClick(Sender, URLorID, Index)
    {
        if(CAccessor.Instance.SingleContext = this.Type)
        {
            if(Index = 1)
            {
                Debug("index")
                Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, this.Settings.Keyword " ")
                this.Settings.DefaultLocation := Filter
            }
        }
    }
    OnOpen(Accessor)
    {
        this.List := Array()
        this.Cleared := false
    }

    OnClose(Accessor)
    {
        for index, ListEntry in this.List
            if(ListEntry.Icon)
                DestroyIcon(ListEntry.Icon)
    }

    RefreshList(Accessor, Filter, LastFilter, KeywordSet, Parameters)
    {
        static Penalty := 0.00001
        if(!KeywordSet && Filter != this.Settings.Keyword)
            return
        Results := Array()

        for index, ListEntry in this.List
        {
            Result := new this.CResult()
            Result.Title := ListEntry.Title
            Result.Path := ListEntry.Path
            Result.Icon := ListEntry.Icon
            Result.Priority -= Penalty * index ;For sorting by day
            Results.Insert(Result)
        }
        return Results
    }

    Copy(Accessor, ListEntry)
    {
        Clipboard := ListEntry.Title
    }

    OnFilterChanged(ListEntry, Filter, LastFilter)
    {
        SetTimer, QueryWeatherResult, -100
        return false
    }

    ShowSettings(PluginSettings, Accessor, PluginGUI)
    {
        AddControl(PluginSettings, PluginGUI, "Edit", "DefaultLocation", "", "", "Default Location:")
    }
    GetFooterText()
    {
        Filter := strTrim(CAccessor.Instance.FilterWithoutTimer, this.Settings.Keyword " ")
        return Filter ? "<a>Set default location</a>" : ""
    }
}

;This function is not moved into the class because it seems possible that AHK can hang up when this function is called via SetTimerF().
QueryWeatherResult:
QueryWeatherResult()
return
QueryWeatherResult()
{
    if(!CAccessor.Instance.GUI)
        return
    Accessor := CAccessor.Instance
    if(InStr(Accessor.FilterWithoutTimer, CWeatherPlugin.Instance.Settings.Keyword " ") != 1)
        return
    Filter := strTrim(Accessor.FilterWithoutTimer, CWeatherPlugin.Instance.Settings.Keyword " ")
    if(RegExMatch(Filter, "^\s*$"))
        Filter .= CWeatherPlugin.Instance.Settings.DefaultLocation

    Debug("Query Weather for " Filter)

    for index, ListEntry in CWeatherPlugin.Instance.List
        if(ListEntry.Icon)
            DestroyIcon(ListEntry.Icon)

    CWeatherPlugin.Instance.List := Array()
    if(Filter)
    {
        static apikey := "e1765e788f29842afa23fafb5bcba9ee"
        static iconApi := "http://openweathermap.org/img/w/"
        static KelvinToCelsius := 273.15
        ApiURi := "http://api.openweathermap.org/data/2.5/weather?q=" uriEncode(Filter)
        ApiURi .= "&appid=" apikey

        Headers := "Content-Type: application/json`n"
        Headers .= "Referer: http://code.google.com/p/7plus/`n"
        Headers .= Settings.Connection.UseProxy && Settings.Connection.ProxyPassword ? "Proxy-Authorization: Basic " Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) : ""

        Options := Settings.Connection.UseProxy ? "Proxy: " Settings.Connection.ProxyAddress ":" Settings.Connection.ProxyPort "`n" : ""

        Debug("HTTPRequest request HEADER:", Headers)
        Debug("HTTPRequest request Options:", Options)
        HttpRequest(ApiURi, WeatherQuery, Headers, Options)

        Debug("HTTPRequest response HEADER:", Headers)
        Debug("HTTPRequest response BODY:", WeatherQuery)

        result := Jxon_Load(WeatherQuery)
        updated = 1970

        if (result.sys.country)
        {
            city := result.name ", " result.sys.country
            low := result.main.temp_min
            high := result.main.temp_max
            updated += result.dt,s
            for index, weather in result.weather
            {
                condition := weather.description
                Icon := weather.icon ".png"
            }

            Headers := "Referer: http://code.google.com/p/7plus/`n"
            Headers .= Settings.Connection.UseProxy && Settings.Connection.ProxyPassword ? "Proxy-Authorization: Basic " Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) : ""
            Options .= "BINARY"

            size := HttpRequest(iconApi "" Icon, WeatherIcon, Headers, Options)
            Debug("HTTPRequest response HEADER:", Headers)
            Debug("HTTPRequest response BODY:", WeatherIcon)
            Debug("HTTPRequest response SIZE:", size)

            if (!FileExist(A_Temp "\7plus\" Icon))
                write_bin(WeatherIcon, A_Temp "\7plus\" Icon, size)
            Debug("Does WeatherIcon File exist? " FileExist(A_Temp "\7plus\" Icon))

            pBitmap := Gdip_CreateBitmapFromFile(A_Temp "\7plus\" Icon, 1)
            hIcon := Gdip_CreateHICONFromBitmap(pBitmap)
            low := Round(low - KelvinToCelsius) ;Convert °K to °C
            high := Round(high - KelvinToCelsius) ;Convert °K to °C

            CWeatherPlugin.Instance.List.Insert(Object("Title", condition " with Low: " low "°C - High: " high "°C", "Path", "Weather in " city, "Icon", hIcon ))
        }
    }
    Accessor.RefreshList()
}