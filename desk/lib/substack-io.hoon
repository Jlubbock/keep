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
  ::  cloudflare 429s burst crawls from datacenter ips: back off before failing
  =/  naps=(list @dr)  ~[~s15 ~m1 ~m4]
  |-  ^-  form:m
  ;<  ~                         bind:m  (send-request:strandio request)
  ;<  res=client-response:iris  bind:m  take-client-response:strandio
  ?>  ?=(%finished -.res)
  =/  code  status-code.response-header.res
  ?:  &(?=(^ naps) |(=(429 code) =(503 code)))
    ;<  ~  bind:m  (sleep:strandio i.naps)
    $(naps t.naps)
  ?.  =(200 code)
    %+  strand-fail:strandio  %substack-http
    ~[leaf+"{(a-co:co code)} on {(trip url)}"]
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
  ::  raw length, not parsed: +arch drops entries, and a short page ends paging
  =/  raw=@ud  ?:(?=([%a *] aj) (lent p.aj) 0)
  =/  page=(list meta:ks)  (arch:sk aj)
  ?:  =(0 raw)  (pure:m acc)
  =/  all  (weld acc page)
  ?:  ?|  (lth raw 20)
          (gth off 10.000)
          ?&  ?=(^ page)
              (lte wen:(rear `(list meta:ks)`page) floor)
          ==
      ==
    (pure:m all)
  ;<  ~  bind:m  (sleep:strandio (div ~s1 4))
  $(acc all, off (add off 20))
--
