/* REXX */                                  
   Address ISPEXEC                          
 "ISREDIT MACRO (PARM)"                     
 "ISREDIT (MEM) = MEMBER"                   
 "ISREDIT (DSN) = DATASET"                  
 Address TSO "EXEC '"DSN"("MEM")' '"PARM"'" 
