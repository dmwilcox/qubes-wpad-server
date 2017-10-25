package main

import (
    "flag"
    "log"
    "net/http"
    "text/template"
)

var proxy = flag.String("proxy", "localhost:8118", "host:port of proxy")

type ProxyPAC struct {
    Proxy string
    ExcludePatterns []string
}

func main() {
    flag.Parse()
    mux :=http.NewServeMux()
    mux.HandleFunc("/", defaultPac)
    mux.HandleFunc("/wpad.dat", defaultPac)
    mux.HandleFunc("/proxy.pac", defaultPac)
    log.Fatal(http.ListenAndServe("localhost:80", mux))
}

func defaultPac(w http.ResponseWriter, req *http.Request) {
    const templ = `function FindProxyForURL(url, host)
    {
            return "PROXY {{.Proxy}}; DIRECT";
    }`
    var pac ProxyPAC
    pac.Proxy = *proxy
    t := template.Must(template.New("proxy.pac").Parse(templ))
    mime := "application/x-ns-proxy-autoconfig"
    w.Header().Add("Content-Type", mime)
    if err := t.Execute(w, pac); err != nil {
        log.Fatal(err)
    }
}
