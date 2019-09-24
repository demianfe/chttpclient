# unifies the api to the standard library

import Uri, httpcore, streams
import asyncjs #https://nim-lang.org/docs/asyncjs.html
               # just overried the same syntax of httpclient but using requests

type 
  Blob* = ref BlobObj
  BlobObj {.importc.} = object of RootObj
    size*: int
    `type`*: cstring

                          
type
  HttpRequest {.importc.} = ref object
  ThisObj {.importc.} = ref object
    readyState, status: int
    responseText, statusText: cstring


const defUserAgent* = "Nim chttpclient/" & NimVersion

type
  HttpClientBase* = ref object of JsRoot
    currentURL: Uri ## Where we are currently connected.
    headers*: HttpHeaders ## Headers to send in requests.
    maxRedirects: int
    userAgent: string
    timeout: int
  
  HttpClient* = ref object of HttpClientBase
  AsyncHttpClient* = ref object of HttpClientBase
  
  Response* = ref object
    version*: string
    status*: string
    headers*: HttpHeaders
    body: string
    bodyStream*: Stream
    
  AsyncResponse* = ref cstring


# binding
proc setRequestHeader(r: HttpRequest; a, b: cstring) {.importcpp: "#.setRequestHeader(@)".}
proc statechange(r: HttpRequest; cb: proc()) {.importcpp: "#.onreadystatechange = #".}
proc send(r: HttpRequest; data: cstring) {.importcpp: "#.send(#)".}
proc send(r: HttpRequest, data: Blob) {.importcpp: "#.send(#)".}
proc open(r: HttpRequest; meth, url: cstring; async: bool) {.importcpp: "#.open(@)".}
proc newRequest(): HttpRequest {.importcpp: "new XMLHttpRequest(@)".}


proc code*(response: Response | AsyncResponse): HttpCode
           {.raises: [ValueError, OverflowError].} =
  ## Retrieves the specified response's ``HttpCode``.
  ##
  ## Raises a ``ValueError`` if the response's ``status`` does not have a
  ## corresponding ``HttpCode``.
  return response.status[0 .. 2].parseInt.HttpCode

           
proc request*(client: HttpClient | AsyncHttpClient, url: string,
              httpMethod: string, body = "",
              headers: HttpHeaders = HttpHeaders(nil)): Future[Response]
              {.async.} =

  var this {.importc: "this".}: ThisObj 
  result = await newPromise() do (resolve: proc(response: Response)):
    let ajax = newRequest()

    ajax.open(httpMethod, url, true)
    for a, b in pairs(headers):
      ajax.setRequestHeader(a, b)
    
    ajax.statechange proc() =    
      if this.readyState == 4:
        if this.status == 200:
          var resp = Response()
          resp.status = $this.status
          resp.body = $this.responseText
          resolve(resp)
        else:
          var resp = Response()
          resp.status = $this.status
          resp.body = $this.responseText
          resolve(resp)

    ajax.send(body) 


proc newHttpClient*(userAgent = defUserAgent, maxRedirects = 5, timeout = -1): HttpClient =
  new result
  result.headers = newHttpHeaders()
  result.userAgent = userAgent
  result.maxRedirects = maxRedirects
  result.timeout = timeout


var newAsyncHttpClient* = newHttpClient
  
proc body*(response: Response): Future[string] {.async.} =
  result = response.body

    
proc get*(client: HttpClient | AsyncHttpClient, url: string): Future[Response] {.async.}=
  result = await request(client, url, $HttpGet, headers=client.headers)

