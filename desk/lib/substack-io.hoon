::  substack-io — strand arms for the substack surface. threads only.
::
/-  spider, ks=keep-sync
/+  strandio, sk=substack
=,  strand=strand:spider
|%
++  fetch-json
  |=  url=@t
  =/  m  (strand ,json)
  ^-  form:m
  ::  cloudflare judges the runtime's default user-agent; name ourselves
  =/  =request:http
    [%'GET' url ~[['accept' 'application/json'] ['user-agent' 'keep-sync']] ~]
  ;<  ~                         bind:m  (send-request:strandio request)
  ;<  res=client-response:iris  bind:m  take-client-response:strandio
  ?>  ?=(%finished -.res)
  ?.  =(200 status-code.response-header.res)
    %+  strand-fail:strandio  %substack-http
    ~[leaf+"{(a-co:co status-code.response-header.res)} on {(trip url)}"]
  ;<  bod=cord                  bind:m  (extract-body:strandio res)
  ?~  jon=(de:json:html bod)
    %+  strand-fail:strandio  %substack-json
    ~[leaf+"unreadable body from {(trip url)}"]
  (pure:m u.jon)
::
::  every archive entry, newest first. paging stops once a page reaches
::  at-or-before `floor`, so an incremental pull stays shallow
++  fetch-archive
  |=  [url=@t floor=@da]
  =/  m  (strand ,(list meta:ks))
  ^-  form:m
  =|  acc=(list meta:ks)
  =/  off=@ud  0
  |-  ^-  form:m
  ;<  aj=json  bind:m
    %-  fetch-json
    (rap 3 url '/api/v1/archive?sort=new&limit=20&offset=' (crip (a-co:co off)) ~)
  =/  page=(list meta:ks)  (arch:sk aj)
  ?~  page  (pure:m acc)
  =/  pg=(list meta:ks)  `(list meta:ks)`page
  =/  all  (weld acc pg)
  =/  eldest=@da  wen:(rear pg)
  ?:  ?|  (lte eldest floor)
          (lth (lent pg) 20)
          (gth off 10.000)
      ==
    (pure:m all)
  ;<  ~  bind:m  (sleep:strandio (div ~s1 4))
  $(acc all, off (add off 20))
--
