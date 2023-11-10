/* REXX */
/* ISPF edit macro to execute the current member being edited. 
   If any changes have been made, then they must be saved first. */
Address ISPEXEC
 "ISREDIT MACRO (PARM)"
 "ISREDIT (MEM) = MEMBER"
 "ISREDIT (DSN) = DATASET"
Address TSO "EXEC '"DSN"("MEM")' '"PARM"'"
