::  keep-mail — mailing the ship's readers. see notes/KEEP-MAIL.md.
::
::    recipients are email addresses, imported from a substack csv on the
::    ship itself. they live here and nowhere else — %keep's lists hold
::    ships. nothing sends without a %send poke.
::
/-  keep
|%
+$  addr  @t                             ::  lowercased email address
::
+$  config
  $:  relay=@t                           ::  the send endpoint, scheme and all
      key=@t                             ::  bearer key for the relay
  ==
::
+$  mstat                                ::  one post, as the mailer knows it
  $%  [%sent wen=@da]
      [%sending ~]
      [%queued tries=@ud]
      [%failed ~]
  ==
::
+$  status                               ::  what the ui renders
  $:  set-up=?
      key=@t                             ::  '' until set; shown, not secret
      readers=@ud
      imported=(unit [added=@ud dropped=@ud])
      stat=(map id:keep mstat)
  ==
::
::  ---- writes: poke %keep-mail-action ----------------------------------------
::
+$  action
  $%  [%config =config]
      [%import raw=@t]                   ::  a substack csv, or bare addresses
      [%remove =addr]
      [%send =id:keep again=?]           ::  the click; again re-mails a sent id
  ==
--
