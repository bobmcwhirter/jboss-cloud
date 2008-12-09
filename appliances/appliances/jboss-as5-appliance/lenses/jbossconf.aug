module JBossConf =
  autoload xfm
  let xfm = transform Shellvars.lns (incl "/etc/jbossas/jbossas.conf")

(* Local Variables: *)
(* mode: caml       *)
(* End:             *)
