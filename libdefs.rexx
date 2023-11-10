/* Rexx */
 
Call setup_libdefs
 
    parm1="Line one"
    parm2="Line two"
Address ispexec
    "ADDPOP ROW(3) COLUMN(13)"
    "DISPLAY PANEL(MSGPAN)"
    "REMPOP ALL"
 
    "ADDPOP ROW(8) COLUMN(22)"
    "DISPLAY PANEL(CONGRAT)"
    "REMPOP ALL"
 
Call destroy_libdefs
 
Exit
 
 
/*********************************************************************/
setup_libdefs: Procedure Expose ddname /* Create and populate temp   */
                                       /* data set and libdef to it  */
ddname = '$'right(time(s),7,'0')     /* create unique ddname         */
Address tso 'ALLOC NEW DEL F('ddname') DIR(20) SP(30) TR RECF(F B)
             BLKS(0) LRECL(80) REU'  /* Allocate data set            */
Address ispexec
'LMINIT DATAID(DID) DDNAME('ddname') ENQ(EXCLU)'
'LMOPEN DATAID(&DID) OPTION(OUTPUT)'
a=1
Do a=a to sourceline()
  Do a=a to sourceline() Until substr(line,1,8)='/*MEMBER'
    line = sourceline(a)
  End
  Parse Var line . memname .
  Do a=a+1 to sourceline() While substr(line,1,2) \= '*/'
    line = sourceline(a)
    If substr(line,1,2) \= '*/' Then
       'LMPUT DATAID(&DID) MODE(INVAR) DATALOC(LINE) DATALEN(80)'
  End
  'LMMADD DATAID(&DID) MEMBER(&MEMNAME)'
  a=a-1
End
'LMFREE DATAID(&DID)'
'LIBDEF ISPPLIB LIBRARY ID('ddname') STACK' /* LIBDEF panels         */
'LIBDEF ISPMLIB LIBRARY ID('ddname') STACK' /* LIBDEF messages       */
'LIBDEF ISPSLIB LIBRARY ID('ddname') STACK' /* LIBDEF Skeletons      */
'LIBDEF ISPTLIB LIBRARY ID('ddname') STACK' /* LIBDEF Tables         */
 ADDRESS TSO "ALTLIB ACTIVATE APPLICATION(CLIST)", /* ALTLIB clist   */
                  "DDNAME("ddname")"
Return
 
/* DESTROY LIBDEFS
   Does just that. */
destroy_libdefs:
Address ispexec
  'LIBDEF ISPPLIB '  /* Remove Panels libdef         */
  'LIBDEF ISPMLIB '  /* Remove messsages libdef      */
  'LIBDEF ISPSLIB '  /* Remove Skeletons libdef      */
  'LIBDEF ISPTLIB '  /* Remove Tables libdef         */
ADDRESS TSO
  "ALTLIB DEACTIVATE APPLICATION(CLIST)" /* Remove CLIST */
  'FREE F('ddname')'     /* Free and delete temp file    */
Return
 
NOP;
/*MEMBER msgpan
)ATTR DEFAULT(%+_)
 + TYPE(TEXT)   INTENS(HIGH) COLOR(BLUE) skip(on)
 % TYPE(TEXT)   INTENS(HIGH) COLOR(WHITE) skip(on)
 @ TYPE(OUTPUT) INTENS(LOW)  COLOR(TURQUOISE) CAPS(OFF)
)BODY WINDOW(34,4)
%
%@parm1
%@parm2
%
)INIT
)PROC
)END
*/
NOP;
/*MEMBER congrat
)attr
# AREA(scrl) extend(on)
+ TYPE(TEXT)   COLOR(BLUE)   INTENS(LOW)  SKIP(ON)
% TYPE(TEXT)   COLOR(WHITE)  INTENS(LOW)  SKIP(ON)
_ TYPE(OUTPUT) COLOR(YELLOW) SKIP(ON) JUST(ASIS) CAPS(OFF)
)body window(20 6)
#h                 #
)area h
 %Congratulations!
)END
*/
