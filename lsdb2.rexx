/* REXX: DB2 Subsystem Status Utility */
/* ------------------------------------
   This script identifies DB2 subsystems on z/OS, their group IDs,
   and statuses (Active, Starting/Stopping, Inactive).
   It supports optional filters via command-line arguments:
     --ALL       : Display all subsystems (default).
     --ACTIVE    : Display only active subsystems.
     --INACTIVE  : Display only inactive subsystems.
--------------------------------------- */
 
parse upper arg parm .  /* Parse the command-line argument */
 
select
  when parm = '' | parm = '--ALL' then option = 'All'
  when parm = '--ACTIVE'          then option = 'Active'
  when parm = '--INACTIVE'        then option = 'Inactive'
  otherwise do
    say "Invalid option specified: " parm
    exit 12
  end
end
 
call get_ssids  /* Retrieve DB2 subsystems */
 
say "SSID     GID      Status"
say "-------- -------- -----------------"
 
do i = 1 to ids.0
  ssid     = ids._ssid.i       /* DB2 Subsystem ID */
  gid      = ids._gid.i        /* Group ID */
  statusid = ids._statid.i     /* Status Code */
  status   = ids._statmsg.i    /* Status Description */
 
  if option = 'All' | option = status then
    say left(ssid, 8) left(gid, 8) status
end
 
exit 0
 
/* ----------------------------------------
   Function: Get DB2 Subsystem Information
   ---------------------------------------- */
get_ssids: procedure expose ids.
  numeric digits 12
  trace 'n'
  parse upper arg trace
 
  if trace <> '' then
    rc = trace(trace)
 
  w_00a5 = x2c('00A5')  /* Early code block identifier */
  parse upper value 'ERLY DSN3' with w_erly w_dsn3 .
 
  ids0 = 0
  ids. = ''  /* Initialize array */
 
  cvt@   = ptr(16)
  jesct@ = ptr(cvt@ + 296)
  ssvt@  = ptr(jesct@ + 24)
 
  do while ssvt@ <> 0
    erly@ = ptr(ssvt@ + 20)
    ssname = stg(ssvt@ + 8, 4)
 
    if erly@ <> 0 then do
      erly = stg(erly@, 124)
 
      if substr(erly, 1, 2) = w_00a5 &,
         substr(erly, 5, 4) = w_erly &,
         substr(erly, 85, 4) = w_dsn3 then do
 
        /* Extract details */
        erly_len      = c2d(substr(erly, 3, 2))
        db2_id        = substr(erly, 9, 4)
        db2_group_id  = substr(erly, 121, 4)
        db2_status_id = 0
        db2_status_msg = 'Inactive'
 
        /* Determine status */
        db2_state = c2d(substr(erly, 36, 1))
        select
          when db2_state = 0 then
            db2_status_msg = 'Inactive'
          when db2_state = 1 then do
            db2_status_id  = 1
            db2_status_msg = 'Starting/Stopping'
          end
          otherwise nop
        end
 
        /* Check for active MSTR address space */
        db2asid# = c2d(substr(erly, 49, 2))
        if db2asid# <> 0 then do
          db2mstr_name = substr(erly, 13, 8)
 
          asvt@     = ptr(cvt@ + 556) + 512
          asvtmaxu@ = ptr(asvt@ + 4)
          ascb@x    = stg(asvt@ + 12 + db2asid# * 4, 4)
 
          if bitand(ascb@x, '80000000'x) = '00000000'x then do
            ascb@ = c2d(ascb@x)
            job   = stg(ptr(ascb@ + 172), 8)
            stc   = stg(ptr(ascb@ + 176), 8)
 
            if stc = db2mstr_name | job = db2mstr_name then do
              db2_status_id  = 2
              db2_status_msg = 'Active'
            end
          end
        end
 
        /* Store subsystem information */
        ids0 = ids0 + 1
        ids._ssid.ids0   = db2_id
        ids._gid.ids0    = db2_group_id
        ids._statid.ids0 = db2_status_id
        ids._statmsg.ids0 = db2_status_msg
      end
    end
    ssvt@ = ptr(ssvt@ + 4)
  end
 
  ids.0 = ids0
  return
 
/* ----------------------------------------
   Helper Functions
---------------------------------------- */
ptr: return c2d(storage(d2x(arg(1)), 4))
stg: return storage(d2x(arg(1)), arg(2))
