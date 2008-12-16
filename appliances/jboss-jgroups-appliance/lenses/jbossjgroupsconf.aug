module JBossJGroupsConf =
  autoload xfm
  let xfm = transform Shellvars.lns (incl "/etc/jboss-jgroups.conf")

(* Local Variables: *)
(* mode: caml       *)
(* End:             *)
