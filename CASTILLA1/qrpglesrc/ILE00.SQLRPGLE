**free
//*********************************************
ctl-opt dftactgrp(*no);


dcl-pr QCMDEXC extpgm ;
    *n char(2560) options(*varsize) const ;
    *n packed(15:5) const ;
end-pr ;

// Estructura de datos de sistema.
dcl-ds *N PSDS;
   pgmname char(10) pos(1);
   pgmjob  char(10) pos(244);
   pgmuser char(10) pos(254);
end-ds;

// Definición de campos de trabajo.
dcl-s currentTime timestamp ;
dcl-s fhoy        date(*ISO);
dcl-s f1          date(*ISO) inz(d'2021-11-08');
dcl-s i  zoned(2);
dcl-s err  zoned(3);
dcl-s dif  zoned(5:2);
dcl-s dif1 zoned(5:2);
dcl-s diault date(*ISO);
dcl-s diaultS char(10);
dcl-s diafin zoned(2:0);
dcl-s mescur zoned(2:0);

dcl-s w_job  zoned(5:0);
dcl-s w_fec  char(8);
dcl-s w_hor  char(4);
dcl-s w_est  char(1);
dcl-s w_sts  char(1);
dcl-s ii     char(2);
dcl-s sabdom zoned(1);
dcl-s sisab  char(1);
dcl-s sidom  char(1);

//* Main ___________________________________________________________

//--------------------------  inicializa tabla.-
 exec sql
      delete from schedule;
//--------------------------

 currenttime = %timestamp();
 fhoy = %date();
 diault=(%date()+%months(1))-%days(%subdt((%date()+%months(1)):*days));
 diaultS = %char(diault);
 diafin = %dec(%subst(diaultS:9:2):2:0);
//--
  i = 1;
  w_job = 1;
  w_hor = '0000';
  w_est = 'A';
  w_sts = ' ';
//------

 for i = 1 by 1 to diafin ;
    if i <= 9;
       ii = '0'+%char(i);
    else;
       ii = %char(i);
    endif;

    w_fec = %subst(diaultS:1:4)+%subst(diaultS:6:2)+ii;

    chk_findesemana();

    if err = 0;
      rtv_horas();
    endif;

 endfor;

 *inlr = *on;
 return;

//* End Main ______________________________________________________

 dcl-proc chk_findesemana;
    err = 0;
    sisab = '';
    sidom = '';
    fhoy  = %date(%dec(w_fec:8:0));
    exec sql select dayOfWeek(:fhoy)
                 into :sabdom
                 from SYSIBM/SYSDUMMY1;
    if sabdom = 7;
       exec sql
       select HORSAB into :sisab from horas where horjob = :w_job limit 1;
       if sisab = 'N';
          err = 1;
       else;
          err = 0;
       endif;
    endif;
    if sabdom = 1;
       exec sql
       select HORDOM into :sidom from horas where horjob = :w_job limit 1;
       if sidom = 'N';
          err = 1;
       else;
          err = 0;
       endif;
    endif;
    if sabdom > 1 and sabdom < 7;
       err = 0;
    endif;
 end-proc;

 dcl-proc rtv_horas;
    err = 0;
    exec sql
       declare c0 cursor for
          select HORTHM
          from castilla1/horas
          where HORJOB = :w_job
          order by HORTHM;

    exec sql open c0;
    exec sql fetch next from c0 into :w_hor;
    Dow SQLSTATE = '00000';
      wrt_sch();
      exec sql fetch next from c0 into :w_hor;
    EndDo;
    exec sql close c0;
 end-proc;

 dcl-proc wrt_sch;
      exec sql
         insert into  SCHEDULE
                (SCHJOB,
                 SCHFEC,
                 SCHHOR,
                 SCHEST,
                 SCHSTS)
         values (:w_job,
                 :w_fec,
                 :w_hor,
                 :w_est,
                 :w_sts);
 end-proc;
//* _______________________________________________________________
