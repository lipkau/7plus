Class CShortenURLAction Extends CAction
{
    static Type := RegisterType(CShortenURLAction, "Shorten a URL")
    static Category := RegisterCategory(CShortenURLAction, "Internet")
    static __WikiLink := "ShortenURL"
    static URL := "${Clip}"
    static Method := "Goo.gl"
    static WriteToClipboard := true
    static WriteToPlaceholder := "ShortURL"

    Execute(Event)
    {
        URL := Event.ExpandPlaceholders(this.URL)
        if(!IsURL(URL))
            return 0
        if(this.Method = "Goo.gl")
            ShortURL := googl(URL)

        if(ShortURL)
        {
            if(this.WriteToClipboard)
            Clipboard := ShortURL
            if(this.WriteToPlaceholder)
            EventSystem.GlobalPlaceholders[this.WriteToPlaceholder] := ShortURL
            Notify("URL shortened!", "URL shortened" (this.WriteToClipboard ? " and copied to clipboard!" : "!"), 2, NotifyIcons.Success)
            return 1
        } else {
            Notify("Failed to shorten URL", "An error occured while trying to connect to the server.", 2, NotifyIcons.Error)
            return 0
        }
    }

    DisplayString()
    {
        return "Shorten URL: " this.URL
    }

    GuiShow(GUI, GoToLabel = "")
    {
        static sGUI
        if(GoToLabel = "")
        {
            sGUI := GUI
            this.AddControl(GUI, "Text", "Desc", "This action shortens the URL in the clipboard by using the Goo.gl service. The shortened URL can be written back to clipboard or stored in a placeholder.")
            this.AddControl(GUI, "Edit", "URL", "", "", "URL:", "Placeholders", "Action_ShortenURL_Placeholders")
            this.AddControl(GUI, "Edit", "WriteToPlaceholder", "", "", "hPlaceholder:")
            this.AddControl(GUI, "Checkbox", "WriteToClipboard", "Copy shortened URL to clipboard")
        }
        else if(GoToLabel = "Placeholders")
        ShowPlaceholderMenu(sGUI, "URL")
    }
}
Action_ShortenURL_Placeholders:
GetCurrentSubEvent().GuiShow("", "Placeholders")
return

;Shortens a URL using goo.gl service
;Written By Flak
googl(url)
{
    static apikey := "AIzaSyDGT9QHcU4vE8zuOiGK9t-3CPaoFJ9sDYY"
    ApiURi := "https://www.googleapis.com/urlshortener/v1/url"
    ApiURi .= "?fields=id&key=" apikey

    Headers := "Content-Type: application/json`n"
    Headers .= "Referer: http://code.google.com/p/7plus/`n"
    ; if (Settings.Connection.UseProxy && Settings.Connection.ProxyUser)
        ; Headers .= "Proxy-Authorization: " (Settings.Connection.ProxyAuthType == 2 ? "NTLM " : "Basic ") Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) "`n"
    Headers .= Settings.Connection.UseProxy && Settings.Connection.ProxyPassword ? "Proxy-Authorization: Basic " Base64Encode(Settings.Connection.ProxyUser ":" decrypt(Settings.Connection.ProxyPassword)) : ""

    Options := "Method: POST`n"
    Options .= "Charset: UTF-8`n"
    Options .= Settings.Connection.UseProxy ? "Proxy: " Settings.Connection.ProxyAddress ":" Settings.Connection.ProxyPort "`n" : ""

    POSTdata := "{""longUrl"": """ url """}"

    Debug("HTTPRequest request HEADER:", Headers)
    Debug("HTTPRequest request Options:", Options)

    HTTPRequest(ApiURi , POSTdata, Headers, Options)

    Debug("HTTPRequest response HEADER:", Headers)
    Debug("HTTPRequest response BODY:", POSTdata)

    obj := Jxon_Load(POSTdata)
    return % obj.id
}
