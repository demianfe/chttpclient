# wrapps requestjs for js target and httpclient for c/c++ target

import json, Uri

when defined(js):
  import httpclientjs
  export httpclientjs
    
else:
  # just use sdtlib
  import httpclient
  export httpclient
