::  keep-mail — mailing the ship's readers. see notes/KEEP-MAIL.md.
::
::    the reader list lives here, imported from a substack csv on the ship
::    itself. the relay (keep-posting.com) holds the consent record for
::    every address and gates each send on it: only readers who confirmed
::    by clicking a link the relay sent them are mailed. nothing sends
::    without a %send poke.
::
/-  keep, ks=keep-sync
|%
+$  addr  @t                             ::  lowercased email address
::
+$  config
  $:  relay=@t                           ::  the relay's base url; '' is keep-posting.com
      key=@t                             ::  bearer key for the relay
  ==
::
+$  readers                              ::  the relay's view, as of when we asked
  $:  confirmed=(set addr)
      pending=@ud
      as-of=@da
  ==
::
+$  proof                                ::  ownership of the source publication (imports)
  $:  token=@t                           ::  goes on a page only the owner can edit
      verified=(unit @t)                 ::  the url the relay found it at
  ==
::
+$  mstat                                ::  one post, as the writer sees it
  $%  [%sent wen=@da n=@ud lost=@ud]     ::  reached n; lost bounced or were refused
      [%sending sent=@ud of=@ud]
      [%queued tries=@ud]
      [%failed why=@t]                   ::  a sentence for the writer
  ==
::
+$  status                               ::  what the ui renders
  $:  set-up=?
      key=@t                             ::  '' until set; keep-onboard reads it back
      name=@t                            ::  '' until set; the sender readers see
      readers=@ud                        ::  confirmed: they get each post
      waiting=@ud                        ::  on the ship, not yet confirmed
      as-of=(unit @da)
      asked=(unit @ud)                   ::  the last import: how many were asked to re-confirm
      relayed=(unit @t)                  ::  or why the relay refused it
      proof=(unit proof)                 ::  the optional substack badge
      checked=(unit @t)                  ::  what the last ownership check said, if it failed
      claim=(unit [url=@t =proof:ks])    ::  the substack this ship claims in %keep-sync, as the ship judged it
      trouble=(unit @t)                  ::  the relay rejected this ship's key, or cannot be reached
      subscribe=@t                       ::  the form action readers post to; '' until set up
      stat=(map id:keep mstat)
  ==
::
::  ---- writes: poke %keep-mail-action ----------------------------------------
::
+$  action
  $%  [%config =config]
      [%name name=@t]                    ::  the sender readers see; '' means the ship's name
      [%import raw=@t url=@t]            ::  a substack csv, and the page holding our token
      [%remove =addr]
      [%send =id:keep again=?]           ::  the click; again re-mails a sent id
      [%refresh ~]                       ::  ask the relay who confirmed
      [%verify url=@t]                   ::  ask the relay to find our token at url
      [%reset ~]                         ::  forget the last import's outcome; the card reopens
  ==
--
