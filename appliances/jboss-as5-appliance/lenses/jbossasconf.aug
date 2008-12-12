module JBossAS5Conf =
  autoload xfm
  let xfm = transform Shellvars.lns (incl "/etc/jboss-as5.conf")

(* Local Variables: *)
(* mode: caml       *)
(* End:             *)
