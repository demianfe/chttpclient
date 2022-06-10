import chttpclient
when defined js:
  import std/asyncjs
else:
  import std/asyncdispatch

proc main {.async.} =
  var client = newAsyncHttpClient()
  let resp = await client.get "https://api.teleport.org/api/countries/"
  echo await resp.body

when defined js:
  discard main()
else:
  waitFor main()
