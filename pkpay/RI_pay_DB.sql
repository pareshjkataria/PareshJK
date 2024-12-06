----------------------------------------------------------------------------------------------------
-- PAYROLL - trigger
-- CREATED BY PARESH ON 26/11/2024 - :(
----------------------------------------------------------------------------------------------------
--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--++

--##FUNCTIONS

CREATE OR REPLACE FUNCTION GETEMPNM (PCOMPCD NUMBER,PEMPCD VARCHAR2) RETURN VARCHAR2 IS
  VEMPNM EMPMAS.EMPNM%TYPE;
BEGIN
  SELECT EMPNM INTO VNM FROM EMPMAS WHERE COMPCD = PCOMPCD AND EMPCD = PEMPCD ;
  RETURN VEMPNM;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN '-';
END ;
/


CREATE OR REPLACE FUNCTION GETDEPTNM(PDEPTCD NUMBER) RETURN VARCHAR2 IS
  VDEPTNM DEPTMAS.DEPTNM%TYPE;
BEGIN
  SELECT DEPTNM INTO VDEPTNM FROM DEPTMAS WHERE DEPTCD = PDEPTCD ;
  RETURN VDEPTNM;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN '-';
END ;
/


CREATE OR REPLACE FUNCTION GETDESGNM(PDESGCD NUMBER) RETURN VARCHAR2 IS
  VDESGNM DESGMAS.DESGNM%TYPE;
BEGIN
  SELECT DESGNM INTO VDESGNM FROM DESGMAS WHERE DESGCD = PDESGCD;
  RETURN VNM;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN '-';
END ;
/

CREATE OR REPLACE FUNCTION GETFLOORNM(PFLOORCD NUMBER) RETURN VARCHAR2 IS
  VFLOORNM FLOORMAS.FLOORNM%TYPE;
BEGIN
  SELECT FLOORNM INTO VFLOORNM FROM FLOORMAS WHERE FLOORCD = PFLOORCD;
  RETURN VNM;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN '-';
END ;
/


CREATE OR REPLACE FUNCTION GETCOMPADD (PCOMPCD NUMBER) RETURN VARCHAR2 IS
  VADD  VARCHAR2(500);
BEGIN
	SELECT ADD1||' '||ADD2||' '||ADD3||' '||CITY INTO VADD FROM COMPMAS WHERE COMPCD = PCOMPCD;
	RETURN VADD;
EXCEPTION
	WHEN OTHERS THEN
	RETURN '-';
END;
/


CREATE OR REPLACE FUNCTION GETCOMPNM(PCOMPCD NUMBER) RETURN VARCHAR2 IS
  VCOMPNM COMPMAS.COMPNM%TYPE;
BEGIN
  SELECT COMPNM INTO VCOMPNM FROM COMPMAS WHERE COMPCD = PCOMPCD;
  RETURN VNM;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN '-';
END;
/


CREATE OR REPLACE FUNCTION GETEMPADD(PCOMPCD NUMBER, PFYCD NUMBER, PEMPCD VARCHAR2) RETURN VARCHAR2 IS
  VADDRESS    VARCHAR2(1000);
BEGIN
 SELECT ADD1||' '||ADD2||' '||ADD3||CITY  INTO VADDRESS FROM EMPMAS WHERE COMPCD = PCOMPCD AND FYCD = PFYCD AND EMPCD = PEMPCD;
 RETURN VADDRESS;
EXCEPTION
  WHEN OTHERS THEN
  RETURN '-';
END;
/


CREATE OR REPLACE FUNCTION GETEMPSHORTNM(PCOMPCD NUMBER, PEMPCD VARCHAR2) RETURN VARCHAR2 IS
  VSHORTNM EMPMAS.SHORTNM%TYPE;
BEGIN
  SELECT SHORTNM INTO VSHORTNM FROM EMPMAS WHERE COMPCD = PCOMPCD AND EMPCD = PEMPCD;
  RETURN VSHORTNM;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  RETURN '-';
  WHEN OTHERS THEN
  RETURN '-';
END;
/

CREATE OR REPLACE FUNCTION GETENDDATE (PCOMPCD NUMBER, PFYCD NUMBER) RETURN DATE IS
  VDATE DATE;
BEGIN
  SELECT TDATE INTO VDATE FROM FYMAS WHERE COMPCD = PCOMPCD AND FYCD=PFYCD ;
  RETURN VDATE ;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION GETFYCD(PCOMPCD NUMBER, PDATE DATE) RETURN NUMBER IS
  VFYCD NUMBER;
BEGIN
  SELECT FYCD INTO VFYCD FROM FYMAS WHERE COMPCD = PCOMPCD AND PDATE BETWEEN FDATE AND TDATE ;
  RETURN VFYCD;
EXCEPTION
  WHEN OTHERS THEN
  RETURN NULL;
END;
/


CREATE OR REPLACE FUNCTION GETGENDER(PCOMPCD NUMBER,PEMPCD VARCHAR2) RETURN VARCHAR2 IS
  VGENDER VARCHAR2(5);
BEGIN
SELECT GENDER INTO VGENDER FROM EMPMAS WHERE COMPCD = PCOMPCD AND EMPCD = PEMPCD;
  RETURN VGENDER;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  RETURN '-';
END;
/

CREATE OR REPLACE FUNCTION ISVALIDDATE(PCOMPCD NUMBER, PFYCD NUMBER, PDATE DATE) RETURN BOOLEAN IS
  A  VARCHAR2(2);
BEGIN
    BEGIN
      SELECT 'Y' INTO A FROM FYMAS WHERE COMPCD=PCOMP AND FYCD=PFYCD AND PDATE BETWEEN FDATE AND TDATE ;
    EXCEPTION
     WHEN OTHERS THEN
     A :='N' ;
    END ;

    IF A ='Y' THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
END;
/

CREATE OR REPLACE FUNCTION MYDATE RETURN DATE IS
  VDATE DATE := SYSDATE;
  VNUM  NUMBER;
BEGIN
  LOOP
    SELECT COUNT(*) INTO VNUM FROM HOLIDAYS WHERE CURDATE = TRUNC(VDATE);

    IF TO_CHAR(VDATE,'DY') <> 'SUN' AND VNUM = 0 THEN
       RETURN VDATE ;
       EXIT;
    ELSE
       VDATE := VDATE - 1;
    END IF;
  END LOOP;
END;
/

 
CREATE OR REPLACE PROCEDURE ADVANCESALARY
  (PCOMP NUMBER, PEMP VARCHAR2, PWD NUMBER, PPD NUMBER,
   PSAL IN OUT SALTRAN%ROWTYPE) IS

  CURSOR CUR_SLAB IS SELECT NVL (BASIC,0) BASIC,NVL (DA,0) DA,NVL (HRA,0) HRA,NVL (MEDIREMB,0) MEDIREMB,
   NVL (TRANSPORT,0) TRANSPORT,NVL (CHILD,0) CHILD,NVL (PF,'N') PF, NVL (ESIC,'N') ESIC,
   BANKNO,BANKNM,GETFLOORCD(COMPCD,EMPCD) FLOOR,GETDEPTCD(COMPCD,EMPCD) DEPTCD,TOTPAY REALSAL FROM EMPMAS
  WHERE COMPCD = PCOMP AND EMPCD = PEMP ;

  CURSOR CUR_GOVT IS SELECT * FROM GOVTRULES WHERE COMPCD = PCOMP ;

  SLAB  CUR_SLAB%ROWTYPE ;
  RULES CUR_GOVT%ROWTYPE ;
BEGIN
  OPEN CUR_GOVT ; FETCH CUR_GOVT INTO RULES ; CLOSE CUR_GOVT ;
  OPEN CUR_SLAB ; FETCH CUR_SLAB INTO SLAB ; CLOSE CUR_SLAB ;

  PSAL.BANKNO := SLAB.BANKNO ;
  PSAL.BANKNM := SLAB.BANKNM ;
  PSAL.FLOORCD := SLAB.FLOOR ;
  PSAL.DEPTCD := SLAB.DEPTCD ;

  PSAL.BASIC := 0;
  PSAL.DA := 0;
  PSAL.HRA := 0;
  PSAL.MEDIREMB := 0;
  PSAL.TRANSPORT := 0;
  PSAL.EA := 0;
  
  PSAL.REALSAL := 0;
  PSAL.BASICS := 0;
  PSAL.ALLOWANCES := 0;


  PSAL.EBASIC := 0 ;
  PSAL.EDA := 0;
  PSAL.EHRA := 0;
  PSAL.EMEDIREMB := 0;
  PSAL.ETRANSPORT := 0;
  PSAL.EEA := 0;

  PSAL.EBASICS := 0;
  PSAL.EALLOWANCES := 0;
  PSAL.GROSSSAL := 0;
  PSAL.PFGROSS := 0 ;

    PSAL.EMPPFPER := RULES.EMPPFPER ;
    PSAL.COMPTOTPFPER := RULES.COMPTOTPFPER ;
    PSAL.COMPFPFPER := RULES.COMPFPFPER ;
    PSAL.COMPPFPER := RULES.COMPPFPER ;
    PSAL.EMPESICPER := RULES.EMPESICPER ;
    PSAL.COMPESICPER := RULES.COMPESICPER ;

    PSAL.EMPPF := 0;
    PSAL.COMPTOTPF := 0 ;
    PSAL.COMPPF := 0 ;
    PSAL.COMPFPF := 0;
    PSAL.ESICGROSS := 0 ;
  
    PSAL.EMPESIC := 0;
    PSAL.COMPESIC := 0;
    PSAL.PT := 0 ;

    PSAL.TOTDED := 0;
    PSAL.NETPAY := 0;
END;
/
 
CREATE OR REPLACE PROCEDURE CALC_BONUS
  (PCOMP NUMBER, PEMP VARCHAR2, PWD NUMBER, PPD NUMBER,
   PSAL IN OUT SALTRAN%ROWTYPE) IS

  CURSOR CUR_SLAB IS SELECT NVL (BASIC,0) BASIC,NVL (DA,0) DA,NVL (HRA,0) HRA,NVL (MEDIREMB,0) MEDIREMB,
   NVL (TRANSPORT,0) TRANSPORT,NVL (CHILD,0) CHILD,NVL (PF,'N') PF, NVL (ESIC,'N') ESIC,
   BANKNO,BANKNM,GETFLOORCD(COMPCD,EMPCD) FLOOR,GETDEPTCD(COMPCD,EMPCD) DEPTCD,TOTPAY REALSAL FROM EMPMAS
  WHERE COMPCD = PCOMP AND EMPCD = PEMP ;

  CURSOR CUR_GOVT IS SELECT * FROM GOVTRULES WHERE COMPCD = PCOMP ; 	

  SLAB  CUR_SLAB%ROWTYPE ;
  RULES CUR_GOVT%ROWTYPE ;
BEGIN
  OPEN CUR_GOVT ; FETCH CUR_GOVT INTO RULES ; CLOSE CUR_GOVT ;
  OPEN CUR_SLAB ; FETCH CUR_SLAB INTO SLAB ; CLOSE CUR_SLAB ;

  PSAL.BANKNO := SLAB.BANKNO ;
  PSAL.BANKNM := SLAB.BANKNM ;
  PSAL.FLOORCD := SLAB.FLOOR ;
  PSAL.DEPTCD := SLAB.DEPTCD ;

  PSAL.BASIC := NVL (SLAB.BASIC,0) ;
  PSAL.DA := NVL (SLAB.DA,0) ;
  PSAL.HRA := NVL (SLAB.HRA,0) ;
  PSAL.MEDIREMB:= NVL(SLAB.MEDIREMB,0);
  PSAL.TRANSPORT := NVL (SLAB.TRANSPORT,0) ;
  PSAL.EA := NVL (SLAB.CHILD,0) ;
  PSAL.REALSAL := NVL (SLAB.REALSAL,0) ;
  PSAL.BASICS := NVL (SLAB.BASIC,0) + NVL (SLAB.DA,0) ;
  PSAL.ALLOWANCES := NVL (SLAB.HRA,0)+ NVL(SLAB.MEDIREMB,0) + NVL (SLAB.TRANSPORT,0) + NVL (SLAB.CHILD,0) ;


  PSAL.EBASICS := ROUND (NVL (PSAL.BONUSQUALAMT,0) * 20 / 100) ;
  PSAL.EBASIC := ROUND ((NVL (PSAL.BONUSQUALAMT,0) * 67 / 100) * 20 / 100) ;
  PSAL.EDA := PSAL.EBASICS - PSAL.EBASIC ;



  PSAL.EHRA := 0 ;
  PSAL.EMEDIREMB:= 0;
  PSAL.ETRANSPORT := 0 ;
  PSAL.EEA := 0 ;
  PSAL.EALLOWANCES := 0 ;

  PSAL.GROSSSAL := PSAL.EBASIC + PSAL.EDA + PSAL.EHRA + PSAL.EMEDIREMB + PSAL.ETRANSPORT + PSAL.EEA ;

  PSAL.PFGROSS := 0 ;

  PSAL.EMPPFPER := RULES.EMPPFPER ;
  PSAL.COMPTOTPFPER := RULES.COMPTOTPFPER ;
  PSAL.COMPFPFPER := RULES.COMPFPFPER ;
  PSAL.COMPPFPER := RULES.COMPPFPER ;
  PSAL.EMPESICPER := RULES.EMPESICPER ;
  PSAL.COMPESICPER := RULES.COMPESICPER ;



    PSAL.EMPPF := 0;

    PSAL.COMPTOTPF := 0 ;

    PSAL.COMPPF := 0 ;

    PSAL.COMPFPF := 0 ;



    PSAL.EMPESIC :=  0 ;

    PSAL.COMPESIC := 0 ;


    PSAL.PT := 0 ;

  PSAL.TOTDED := PSAL.EMPPF + PSAL.EMPESIC + PSAL.PT ;
  PSAL.NETPAY := PSAL.GROSSSAL - PSAL.TOTDED ;
END ;
/


CREATE OR REPLACE PROCEDURE CALC_LEAVE
  (PCOMP NUMBER, PEMP VARCHAR2, PWD NUMBER, PPD NUMBER,
   PSAL IN OUT SALTRAN%ROWTYPE) IS

  CURSOR CUR_SLAB IS SELECT NVL (BASIC,0) BASIC,NVL (DA,0) DA,NVL (HRA,0) HRA,NVL (MEDIREMB,0) MEDIREMB,
   NVL (TRANSPORT,0) TRANSPORT,NVL (CHILD,0) CHILD,NVL (PF,'N') PF, NVL (ESIC,'N') ESIC,
   BANKNO,BANKNM,GETFLOORCD(COMPCD,EMPCD) FLOOR,GETDEPTCD(COMPCD,EMPCD) DEPTCD,TOTPAY REALSAL FROM EMPMAS
  WHERE COMPCD = PCOMP AND EMPCD = PEMP ;

  CURSOR CUR_GOVT IS SELECT * FROM GOVTRULES WHERE COMPCD = PCOMP ;

  SLAB  CUR_SLAB%ROWTYPE ;
  RULES CUR_GOVT%ROWTYPE ;
BEGIN
  OPEN CUR_GOVT ; FETCH CUR_GOVT INTO RULES ; CLOSE CUR_GOVT ;
  OPEN CUR_SLAB ; FETCH CUR_SLAB INTO SLAB ; CLOSE CUR_SLAB ;

  PSAL.BANKNO := SLAB.BANKNO ;
  PSAL.BANKNM := SLAB.BANKNM ;  
  PSAL.FLOORCD := SLAB.FLOOR ;
  PSAL.DEPTCD := SLAB.DEPTCD ;

  PSAL.BASIC := NVL (SLAB.BASIC,0) ;
  PSAL.DA := NVL (SLAB.DA,0) ;
  PSAL.HRA := NVL (SLAB.HRA,0) ;
  PSAL.MEDIREMB := NVL(SLAB.MEDIREMB,0);
  PSAL.TRANSPORT := NVL (SLAB.TRANSPORT,0) ;
  PSAL.EA := NVL (SLAB.CHILD,0) ;
  PSAL.REALSAL := NVL (SLAB.REALSAL,0) ;
  PSAL.BASICS := NVL (SLAB.BASIC,0) + NVL (SLAB.DA,0) ;
  PSAL.ALLOWANCES := NVL (SLAB.HRA,0)+ NVL(SLAB.MEDIREMB,0) + NVL (SLAB.TRANSPORT,0) + NVL (SLAB.CHILD,0) ;


  PSAL.EBASIC := ROUND (NVL (SLAB.BASIC,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EDA := ROUND (NVL (SLAB.DA,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EHRA := ROUND (NVL (SLAB.HRA,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EMEDIREMB := ROUND (NVL(SLAB.MEDIREMB,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.ETRANSPORT := ROUND (NVL (SLAB.TRANSPORT,0) * NVL (PPD,0) / NVL (PWD,0));
  PSAL.EEA := ROUND (NVL (SLAB.CHILD,0) * NVL (PPD,0) / NVL (PWD,0));
  PSAL.EBASICS := NVL (PSAL.EBASIC,0) + NVL (PSAL.EDA,0) ;
  PSAL.EALLOWANCES := NVL (PSAL.EHRA,0)+ NVL(PSAL.EMEDIREMB,0) + NVL (PSAL.ETRANSPORT,0) + NVL (PSAL.EEA,0) ;

  PSAL.GROSSSAL := PSAL.EBASIC + PSAL.EDA + PSAL.EHRA + PSAL.EMEDIREMB + PSAL.ETRANSPORT + PSAL.EEA ;

-- PF EFFECT DISABLE BY KISHORE ,REQUEST BY KRUTI
/*
  IF SLAB.PF = 'Y' OR PSAL.BASICS <= RULES.PFLIMIT THEN
    PSAL.PFGROSS := LEAST (PSAL.EBASICS,RULES.PFLIMIT) ;
  ELSE
    PSAL.PFGROSS := 0 ;
  END IF ;
  
  */
      PSAL.PFGROSS := 0 ;

/*   PSAL.EMPPFPER := RULES.EMPPFPER ;
    PSAL.COMPTOTPFPER := RULES.COMPTOTPFPER ;
    PSAL.COMPFPFPER := RULES.COMPFPFPER ;
    PSAL.COMPPFPER := RULES.COMPPFPER ;
    PSAL.EMPESICPER := RULES.EMPESICPER ;
    PSAL.COMPESICPER := RULES.COMPESICPER ;

*/
    PSAL.EMPPFPER := 0 ;
    PSAL.COMPTOTPFPER := 0 ;
    PSAL.COMPFPFPER := 0 ;
    PSAL.COMPPFPER := 0 ;
    PSAL.EMPESICPER := 0 ;
    PSAL.COMPESICPER := 0 ;

/*  PSAL.EMPPF := ROUND (PSAL.PFGROSS * RULES.EMPPFPER / 100) ;

    PSAL.COMPTOTPF := ROUND (PSAL.PFGROSS * RULES.COMPTOTPFPER / 100) ;

    PSAL.COMPPF := ROUND (PSAL.PFGROSS * RULES.COMPPFPER / 100) ;

    PSAL.COMPFPF := NVL (PSAL.COMPTOTPF,0) - NVL (PSAL.COMPPF,0);

*/
    PSAL.EMPPF     := 0 ;
    PSAL.COMPTOTPF := 0;
    PSAL.COMPPF    := 0;
    PSAL.COMPFPF   := 0;
    

--  IF SLAB.ESIC = 'Y' OR (SLAB.BASIC + SLAB.DA + SLAB.TRANSPORT
--                         + SLAB.CHILD + SLAB.HRA + SLAB.MEDIREMB ) <= RULES.ESICLIMIT THEN
--    PSAL.ESICGROSS := NVL (PSAL.EBASIC,0) + NVL (PSAL.EDA,0) +
--                      NVL (PSAL.ETRANSPORT,0) +
--                      NVL (PSAL.EA,0) + NVL (PSAL.EHRA,0)+ NVL(PSAL.EMEDIREMB,0) ;

--  ELSE
    PSAL.ESICGROSS := 0 ;
--  END IF ;
     PSAL.EMPESIC  := CEIL (PSAL.ESICGROSS * RULES.EMPESICPER / 100) ;
     PSAL.COMPESIC := CEIL (PSAL.ESICGROSS * RULES.COMPESICPER / 100) ;
   

--  IF PSAL.GROSSSAL BETWEEN 0 AND 2999 THEN
    PSAL.PT := 0 ;
 /* ELSIF PSAL.GROSSSAL BETWEEN 3000 AND 5999 THEN
    PSAL.PT := 20 ;
  ELSIF PSAL.GROSSSAL BETWEEN 6000 AND 8999 THEN
    PSAL.PT := 40 ;
  ELSIF PSAL.GROSSSAL BETWEEN 9000 AND 11999 THEN
    PSAL.PT := 60 ;
  ELSIF PSAL.GROSSSAL >= 12000 THEN
    PSAL.PT := 80 ;
  END IF ; */

  PSAL.TOTDED := PSAL.EMPPF + PSAL.EMPESIC + PSAL.PT ;
  PSAL.NETPAY := PSAL.GROSSSAL - PSAL.TOTDED ;
END ;
/


CREATE OR REPLACE PROCEDURE CALC_SAL
  (PCOMP NUMBER, PEMP VARCHAR2, PWD NUMBER, PPD NUMBER,
   PSAL IN OUT SALTRAN%ROWTYPE) IS

  CURSOR CUR_SLAB IS SELECT NVL (BASIC,0) BASIC,NVL (DA,0) DA,NVL (HRA,0) HRA,NVL (MEDIREMB,0) MEDIREMB,
   NVL (TRANSPORT,0) TRANSPORT,NVL (CHILD,0) CHILD,NVL (PF,'N') PF, NVL (ESIC,'N') ESIC,
   BANKNO,BANKNM,GETFLOORCD(COMPCD,EMPCD) FLOOR,GETDEPTCD(COMPCD,EMPCD) DEPTCD,TOTPAY REALSAL FROM EMPMAS
  WHERE COMPCD = PCOMP AND EMPCD = PEMP ;

  CURSOR CUR_GOVT IS SELECT * FROM GOVTRULES WHERE COMPCD = PCOMP;

  SLAB  CUR_SLAB%ROWTYPE ;
  RULES CUR_GOVT%ROWTYPE ;
  PPT NUMBER;

/*  P_EBASIC     NUMBER;
  P_EDA        NUMBER;
  P_EHRA       NUMBER;
  P_EMEDIREMB  NUMBER;
  P_ETRANSPORT NUMBER;
  */
BEGIN
  OPEN CUR_GOVT ; FETCH CUR_GOVT INTO RULES ; CLOSE CUR_GOVT ;
  OPEN CUR_SLAB ; FETCH CUR_SLAB INTO SLAB ; CLOSE CUR_SLAB ;

  PSAL.BANKNO := SLAB.BANKNO ;
  PSAL.BANKNM := SLAB.BANKNM ;
  PSAL.FLOORCD := SLAB.FLOOR ;
  PSAL.DEPTCD := SLAB.DEPTCD ;

  PSAL.BASIC := NVL (SLAB.BASIC,0) ;
  PSAL.DA := NVL (SLAB.DA,0) ;
  PSAL.HRA := NVL (SLAB.HRA,0) ;
  PSAL.MEDIREMB := NVL (SLAB.MEDIREMB,0) ;
  PSAL.TRANSPORT := NVL (SLAB.TRANSPORT,0) ;

  IF PSAL.SALTYPE<>'N' THEN
    PSAL.EA := NVL (SLAB.CHILD,0) ;
  ELSE
    PSAL.EA := 0;
  END IF;

  PSAL.REALSAL := NVL (SLAB.REALSAL,0) ;
  PSAL.BASICS := NVL (SLAB.BASIC,0) + NVL (SLAB.DA,0) ;
  PSAL.ALLOWANCES := NVL (SLAB.HRA,0)+ NVL (SLAB.MEDIREMB,0) + NVL (SLAB.TRANSPORT,0) + NVL (SLAB.CHILD,0) ;

/* 
  P_EBASIC        :=  ROUND(SLAB.BASIC / P_PWD,3) ;
  P_EDA           :=  ROUND(SLAB.DA / PWD,3) ;
  P_EHRA          :=  ROUND(SLAB.HRA / PWD,3) ;
  P_EMEDIREMB     :=  ROUND(SLAB.MEDIREMB / PWD,3) ;
  P_ETRANSPORT    :=  ROUND(SLAB.TRANSPORT / PWD,3) ;
  
  P_EBASIC        :=  NVL(SLAB.BASIC,0)     - ROUND(P_EBASIC * ( NVL(PWD,0) - NVL(PPD,0)),0);
  P_EDA           :=  NVL(SLAB.DA,0)        - ROUND(P_EDA * ( NVL(PWD,0) - NVL(PPD,0)),0);
  P_EHRA          :=  NVL(SLAB.HRA,0)       -ROUND(P_EHRA * ( NVL(PWD,0) - NVL(PPD,0)),0);
  P_EMEDIREMB     :=  NVL(SLAB.MEDIREMB,0)  -ROUND(P_EMEDIREMB * ( NVL(PWD,0) - NVL(PPD,0)),0);
  P_ETRANSPORT    :=  NVL(SLAB.TRANSPORT,0) -ROUND(P_ETRANSPORT * ( NVL(PWD,0) - NVL(PPD,0)),0);
  
  PSAL.EBASIC     := P_EBASIC;
  PSAL.EDA        := P_EDA;
  PSAL.EHRA       := P_EHRA;
  PSAL.EMEDIREMB  := P_EMEDIREMB;
  PSAL.ETRANSPORT := P_ETRANSPORT;
*/

   
  PSAL.EBASIC := ROUND (NVL (SLAB.BASIC,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EDA := ROUND (NVL (SLAB.DA,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EHRA := ROUND (NVL (SLAB.HRA,0) * NVL (PPD,0) / NVL (PWD,0)) ;
  PSAL.EMEDIREMB := ROUND ( NVL (SLAB.MEDIREMB,0)* NVL(PPD,0) / NVL(PWD,0)) ;
  PSAL.ETRANSPORT := ROUND (NVL (SLAB.TRANSPORT,0) * NVL (PPD,0) / NVL (PWD,0));

  IF PSAL.SALTYPE<>'N' THEN
     PSAL.EEA := NVL (SLAB.CHILD,0);
  ELSE
     PSAL.EEA := 0;
  END IF;

  PSAL.EBASICS := NVL (PSAL.EBASIC,0) + NVL (PSAL.EDA,0) ;
  PSAL.EALLOWANCES := NVL (PSAL.EHRA,0)+ NVL (PSAL.EMEDIREMB,0) + NVL (PSAL.ETRANSPORT,0) + NVL (PSAL.EEA,0) ;

  PSAL.GROSSSAL := PSAL.EBASIC + PSAL.EDA + PSAL.EHRA + PSAL.EMEDIREMB + PSAL.ETRANSPORT + PSAL.EEA ;

  IF SLAB.PF = 'Y' OR PSAL.BASICS <= RULES.PFLIMIT THEN
    PSAL.PFGROSS := LEAST (PSAL.EBASICS,RULES.PFLIMIT) ;
  ELSE
    PSAL.PFGROSS := 0 ;
  END IF ;

    PSAL.EMPPFPER := RULES.EMPPFPER ;
    PSAL.COMPTOTPFPER := RULES.COMPTOTPFPER ;
    PSAL.COMPFPFPER := RULES.COMPFPFPER ;
    PSAL.COMPPFPER := RULES.COMPPFPER ;
    PSAL.EMPESICPER := RULES.EMPESICPER ;
    PSAL.COMPESICPER := RULES.COMPESICPER ;



    PSAL.EMPPF := ROUND (PSAL.PFGROSS * RULES.EMPPFPER / 100) ;

    PSAL.COMPTOTPF := ROUND (PSAL.PFGROSS * RULES.COMPTOTPFPER / 100) ;

    PSAL.COMPPF := ROUND (PSAL.PFGROSS * RULES.COMPPFPER / 100) ;

    PSAL.COMPFPF := NVL (PSAL.COMPTOTPF,0) - NVL (PSAL.COMPPF,0);



  IF SLAB.ESIC = 'Y' OR (SLAB.BASIC + SLAB.DA + SLAB.TRANSPORT
                         + SLAB.CHILD + SLAB.HRA + SLAB.MEDIREMB ) <= RULES.ESICLIMIT THEN
    PSAL.ESICGROSS := NVL (PSAL.EBASIC,0) + NVL (PSAL.EDA,0) +
                      NVL (PSAL.ETRANSPORT,0) +
                      NVL (PSAL.EA,0) + NVL (PSAL.EHRA,0) + NVL(PSAL.EMEDIREMB,0) ;

  ELSE
    PSAL.ESICGROSS := 0 ;
  END IF ;
    PSAL.EMPESIC := CEIL (PSAL.ESICGROSS * RULES.EMPESICPER / 100) ;
 
IF PEMP='KMK002' THEN 
    PSAL.COMPESIC := 0;
ELSE
    PSAL.COMPESIC := CEIL (PSAL.ESICGROSS * RULES.COMPESICPER / 100) ;
END IF;
    

  SELECT MAX(PT) INTO PPT FROM PTSLAB WHERE COMPCD=PCOMP AND PSAL.GROSSSAL BETWEEN FGROSSSAL AND TGROSSSAL;
  PSAL.PT:=PPT;
    

  PSAL.TOTDED := PSAL.EMPPF + PSAL.EMPESIC + PSAL.PT + NVL (PSAL.TDS,0)  ;
  PSAL.NETPAY := PSAL.GROSSSAL - PSAL.TOTDED - NVL (PSAL.ADVANCE,0) ;


END ;
/



--## UNUSED AS ON 30/09/2024


CREATE OR REPLACE VIEW MY_ATTDETAIL AS
SELECT GETEMPNM(1,USERID)NM, USERID EMPCD,TO_DATE(EDATETIME) EDATE,TO_CHAR(EDATETIME,'HH24.MI') ETIME,
TO_NUMBER(TO_CHAR(EDATETIME,'HH24MISS')) MY_SEQ,EVTSEQNO,USRREFCODE,MID
FROM COSEC.MX_ACSEVENTTRN
WITH READ ONLY 
/



CREATE OR REPLACE VIEW ATTENDANCE AS
SELECT A.NM,A.EMPCD,A.EDATE,A.ETIME IN_TIME ,DECODE(B.ETIME,A.ETIME,0,B.ETIME) OUT_TIME,A.MID FROM
  (Select NM,EMPCD,EDATE,ETIME,MID From My_Attdetail t WHERE MY_SEQ = (SELECT MIN(MY_SEQ)  FROM MY_ATTDETAIL WHERE EMPCD=T.EMPCD AND EDATE=T.EDATE) ) A ,
  (Select NM,EMPCD,EDATE,ETIME,MID From My_Attdetail t WHERE MY_SEQ = (SELECT MAX(MY_SEQ) FROM MY_ATTDETAIL WHERE EMPCD=T.EMPCD AND EDATE=T.EDATE) ) B
WHERE A.EMPCD=B.EMPCD(+) AND A.EDATE=B.EDATE(+)
WITH READ ONLY
/




CREATE OR REPLACE VIEW EMPMAS_TP AS
SELECT NM,EMPCD,EDATE,MAX(ETIME) ETIME,DECODE(MOD(COUNT(0),2),0,'OUT','IN') FLAG,COUNT(0) XCOUNT From My_Attdetail t
GROUP BY NM ,EMPCD,EDATE
/


create or replace view inout_flag as
Select  NM,EMPCD,EDATE,MAX(ETIME) ETIME,DECODE(MOD(COUNT(0),2),0,'OUT','IN') FLAG,COUNT(0) XCOUNT From My_Attdetail t
Group BY NM ,EMPCD,EDATE
/



CREATE OR REPLACE VIEW SUBDEPTMAS AS
SELECT PARTYCD SUBDEPTCD,PARTYNM SUBDEPTNM FROM NEWMFG.PARTYMAS
WHERE COMPCD=1 AND TYPE IN ('CLVDEPT','MFGDEPT','PAYROLL') AND STATUS ='Y'
/


CREATE OR REPLACE FUNCTION GETSUBDEPTNM (PSUBDEPTCD NUMBER) RETURN VARCHAR2 IS
  VNM VARCHAR2 (50) ;
BEGIN
  SELECT SUBDEPTNM INTO VNM FROM SUBDEPTMAS WHERE SUBDEPTCD=PSUBDEPTCD ;
  RETURN VNM;
EXCEPTION
  WHEN OTHERS THEN RETURN VNM ;
END ;
/




CREATE OR REPLACE VIEW VIEW_EMPMAS AS
SELECT
       A.COMPCD,
       A.EMPCD,
       EMPNM,
       SUBSTR(EMPNM,1,INSTR(EMPNM,' ',1)) FIRSTNM,
       SUBSTR(EMPNM,INSTR(EMPNM,' ',-1))  LASTNM,
       SHORTNM,
       FATHERNM,
       MOTHERNM,
       HUSBANDNM,
       PADD1,
       PADD2,
       PADD3,
       PCITY,
       SEX,
       BIRTHDATE,
       BASIC,
       DA,
       HRA,
       CHILD,
       TRANSPORT,
       TOTPAY,
       TDS,
       PFNO,
       ESICNO,
       BANKNO,
       PF,
       ESIC,
       PT,
       ITAX,
       PFPER,
       ESICPER,
       PTAXPER,
       ITAXPER,
       MEDIREMB,
       PANNO,
       BANKNM,
       BRANCH,
       BLOODGRP,
       EXPERIENCE,
       CONTACT1,
       CONTACT2,
       STATUS,
       INTIME,
       OUTTIME,
       TOTMIN,
       DIFTIME,
       BIRTHPLACE,
       BIRTHDISTRICT,
       BIRTHSTATE,
       QUAL,
       PINCODE,
       COUNTRY,
       STATE,
       EXCEP_TIME,
       AUTO_PUNCH,
       EMP_REFNO,
       REFNM,
       MARITAL_STATUS,
       JOINDATE,
       RESGDATE,
       NOTARYDATE,
       EMPCD_OLD,
       SHIFTNO,
       CHECKERCD,
       SUBSTR(GETEMPNM(A.COMPCD,A.CHECKERCD),1,100) CHECKERNM,
       GRADE,
       IS_CONFIRM,
       CARDISSDATE,
       RESG_TRF_FLAG,
       FYCD,
       DEPTCD,
       SUBSTR(GETDEPTNM(DEPTCD),1,100) DEPTNM,
       SUBDEPTCD,
       SUBSTR(GETSUBDEPTNM(SUBDEPTCD),1,100) SUBDEPTNM,
       FLOOR,
       SUBSTR(GETFLOORNM(FLOOR),1,100) FLOORNM,
       DESG,
       SUBSTR(GETDESGNM(DESG),1,100) DESGNM,
       ADD1,
       ADD2,
       ADD3,
       CITY,
       NOOFCHILD,
       STUDYCHILD,
       TRFFROM,
       TRFFRDATE,
       CFPD,
       TRFTO,
       TRFTODATE,
       INSERTUSER,
       UPDATEUSER,
       IS_FIX_SALARY,
       WEEKOF
  FROM EMPMAS A, EMPMAS_FY B
  WHERE A.COMPCD=B.COMPCD(+) AND A.EMPCD=B.EMPCD(+)
  AND B.FYCD = (SELECT MAX(FYCD) FROM FYMAS) --NEW YEAR MA AA DODING REMOVE KARI....GLOBAL FYCD BADHA REPORT MA PASS KARVU (HAMNA TIME NATHI)
--  AND NVL(IS_CONFIRM,'N') = 'Y'
/


CREATE OR REPLACE PACKAGE PKG_PARAM AS
  PROCEDURE SET_FDATE      (P_FDATE IN DATE);
  PROCEDURE SET_TDATE     (P_TDATE IN DATE);
  PROCEDURE SET_PEMPCD   (P_EMPCD IN VARCHAR2);
  
  FUNCTION  GET_FDATE      RETURN DATE;
  FUNCTION  GET_TDATE      RETURN DATE;
  FUNCTION  GET_PEMPCD    RETURN VARCHAR2;
END PKG_PARAM;
/




CREATE OR REPLACE FUNCTION GETAGE(FDATE DATE, TDATE DATE, PFLAG VARCHAR2) RETURN NUMBER IS
  VYEAR  NUMBER(3);
  VMONTH NUMBER(3);
  VDAYS  NUMBER(3);
BEGIN
  SELECT TRUNC(MONTHS_BETWEEN(TDATE, FDATE) / 12) YEARS,
         TRUNC(MONTHS_BETWEEN(TDATE, FDATE) - (TRUNC(MONTHS_BETWEEN(TDATE, FDATE) / 12) * 12)) MONTHS,
         TRUNC((MONTHS_BETWEEN(TDATE, FDATE) - TRUNC(MONTHS_BETWEEN(TDATE, FDATE))) * 30) DAYS
         INTO VYEAR, VMONTH, VDAYS FROM DUAL;

  IF PFLAG = 'YEAR' THEN
    RETURN VYEAR;
  ELSIF PFLAG = 'MONTH' THEN
    RETURN VMONTH;
  ELSIF PFLAG = 'DAY' THEN
    RETURN VDAYS;
  END IF;
END;
/


--dont use this
CREATE OR REPLACE FUNCTION GetAge(Fdate Date,Tdate Date)  RETURN Varchar2 IS
   Aday     number :=0;
   Amonth   number :=0;
   Ayear    number :=0 ;
   
   Bday     number :=0;
   Bmonth   number :=0;
   Byear    number :=0 ;

   Rday     number;
   RMonth   number;
   RYear    number;
begin
   Aday   := to_number(to_char(fdate,'DD'));
   Bday   := to_number(to_char(tdate,'DD'));
   AMonth := to_number(to_char(fdate,'MM'));
   BMonth := to_number(to_char(tdate,'MM'));
   Ayear  := to_number(to_char(fdate,'YYYY'));
   Byear  := to_number(to_char(tdate,'YYYY'));
  
 if Aday< bday then 

   if Amonth< Bmonth then 
        Ayear := Ayear - 1;
        Aday   :=  Aday + 31 ;
        AMonth := Amonth + 11;
   else
   	    Aday   :=  Aday + to_number(to_char(last_day(fdate),'DD')) ;
   	    Amonth :=  Amonth-1;
   end if;
        Rday := NVL(Aday,0) - NVL(Bday,0);
 else
        Rday := NVL(Aday,0) - NVL(Bday,0);
 end if;   

 if Amonth< Bmonth then 
      Ayear := Ayear - 1;
      AMonth := Amonth + 12;
      Rmonth := Amonth-Bmonth;
 else
      Aday   :=  Aday + to_number(to_char(last_day(fdate),'DD')) ;
      Rmonth := nvl(Amonth,0)-nvl(Bmonth,0);
 end if;

     Ryear   := nvl(Ayear,0) - nvl(Byear,0);
Return (lpad(to_char(ryear),2,0)||'='|| lpad(to_char(rmonth),2,0));    
--     Return (lpad(to_char(ryear),2,0)||lpad(to_char(rmonth),2,0)||pad(to_char(rday),2,0));

END;
/


CREATE OR REPLACE FUNCTION GETCFPD(PCOMPCD NUMBER,PEMPCD VARCHAR2,P_CFPD_FLAG VARCHAR2) RETURN NUMBER IS
  VCD NUMBER (5) ;
  PFYCD NUMBER;
BEGIN 
IF P_CFPD_FLAG='Y' THEN 
  SELECT MAX(FYCD) INTO PFYCD FROM FYMAS ;
  SELECT CFPD INTO VCD FROM EMPMAS_FY  WHERE COMPCD=PCOMPCD AND EMPCD=PEMPCD AND FYCD=PFYCD;
  RETURN VCD;
ELSE
 RETURN 0;
END IF;
 
  
EXCEPTION WHEN OTHERS THEN RETURN 0 ;
END ;
/

create or replace function GetDeptcd (pcompcd number,pempcd varchar2) return varchar2 is
  vcd number (5) ;
  pfycd number;
begin
  Select max(fycd) into pfycd from fymas ;
  Select deptcd into vcd from empmas_fy where compcd=pcompcd and empcd=pempcd and fycd=pfycd;
  return vcd;
exception
  when others then return vcd ;
end ;
/


create or replace function GetDesgCd (pcompcd number,pempcd varchar2) return number is
  vcd number (5) ;
  pfycd number;
begin
  Select max(fycd) into pfycd from fymas ;
  select desg into vcd from empmas_fy  where compcd=pcompcd and empcd=pempcd and fycd=pfycd;
  return vcd;
exception when others then return 0 ;
end ;
/


create or replace function GetEmpMas (pcomp number,pcd varchar2,pnm varchar2) return varchar2 is
  vnm varchar2 (50) ;
begin
IF PNM='JOINDATE' THEN 
  select  JOINDATE into vnm from empmas where compcd = pcomp and empcd=pcd ;
 END IF;
  return vnm;
exception
  when others then return vnm ;
end ;
/


create or replace function GetFloorcd (pcompcd number,pempcd varchar2) return varchar2 is
  vcd number (5) ;
  pfycd number;
begin
  Select max(fycd) into pfycd from fymas ;
  Select Floor into vcd from empmas_fy where compcd=pcompcd and empcd=pempcd and fycd=pfycd;
  return vcd;
exception
  when others then return vcd ;
end ;
/


CREATE OR REPLACE FUNCTION GetHours(pminuts number) RETURN number IS
  vhour number(5,2);
  vmin number;
BEGIN
--	vhour := floor(pminuts/60);
	--return (vhour||'.'||(pminuts-(vhour*60)));
  vhour := Floor     (pminuts/60);
  Vmin  := pMinuts - (vhour*60);
  If Length(vmin) = 1 then 
     Return (vhour||'.0'||(pminuts-(vhour*60)));
  else
     Return (vhour||'.'||(pminuts-(vhour*60))); 
  end if;
     
exception
	when others then
	return 0;
END;
/


CREATE OR REPLACE Function GETINOUT(Pcompcd number,pEmpcd varchar2,flag varchar2) return NUMBER is
  VIN NUMBER;
  VOUT NUMBER;
begin
    SELECT INTIME ,OUTTIME INTO VIN,VOUT FROM EMPMAS WHERE COMPCD=Pcompcd and Empcd=PEmpcd ;
   IF FLAG='I' THEN
     RETURN VIN;
   ELSIF FLAG='O' THEN
     RETURN  VOUT;
   ELSE
     RETURN 0;
     END IF;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   RETURN 0 ;
end ;
/


CREATE OR REPLACE FUNCTION GetMaster(psts char,pcomp number,pemp char) RETURN char is
     vSex varchar2(2);
     vrdt  date;
     vtdt  date;
BEGIN

  If psts='SEX' then 
      Begin
        Select sex into vsex from empmas where compcd=pcomp and empcd=pemp; 
        Return vsex;
      Exception
   	  When others then 
     	  Return ('A'); 
      End ;
   End if;

  If psts='TRNS' then 
      Begin
       Select resgdate into vrdt  from VIEW_empmas where compcd=pcomp and empcd=pemp; 
       Select trftodate into vtdt from VIEW_empmas where compcd=pcomp and empcd=pemp; 
       
       if vrdt is not null then 
           return 'R';
       elsif vtdt is not null then 
           return 'T';
       else 
       	   return 'A';
       end if;	

      Exception
   	  When others then 
     	 Return (NULL); 
      End ;
   End if;

END;
/




CREATE OR REPLACE FUNCTION GetMinutes(pHours number) RETURN number IS
  vMinutes number(10);
BEGIN
  vMinutes := floor(nvl(pHours,0))* 60 ;
  vminutes := vminutes + to_number(substr(to_char(nvl(phours,0),'00.00'),-2,2)); 
  return (vminutes);
END;
/


CREATE OR REPLACE FUNCTION GETSALTYPE (VSALTYPE VARCHAR2) RETURN varchar2 is
  vSALDESC SALTYPE.SALDESC%TYPE;
BEGIN
  SELECT SALDESC INTO VSALDESC FROM SALTYPE WHERE SALTYPE=VSALTYPE ;
  RETURN VSALDESC;
EXCEPTION
  WHEN OTHERS THEN
  RETURN VSALDESC ;
END;
/


CREATE OR REPLACE FUNCTION GetShift(pin number,Pout number) RETURN number IS
   pinmin number;
   poutmin number;
   pshiftno number;
BEGIN
    pInMin    := getminutes  (pIn);
    poutMin  := getminutes  (pOut);
 Begin
    Select Shiftno into pShiftno 
       From Newmfg.Shiftmas  
           Where pinMin between getminutes(start_time-1) and getminutes(start_time+1)
                and poutMin between getminutes(End_time-1) and getminutes(End_time+1) ;
 Exception
    When no_data_found then 
    pshiftno := 0 ;
 End;
      return pshiftno;
END;
/


create or replace function Getstartdate (pcompcd number,pfycd number) return date is
 vdate date;
begin
 select fdate into vdate from fymas where compcd = pcompcd and fycd=pfycd ;
 return vdate ;
exception
 when others then return to_date(null) ;
end ;
/


create or replace function GetSUBDEPTCD (pcompcd number,pempcd varchar2) return varchar2 is
  vSUBDEPTCD NUMBER;
  pfycd      NUMBER;
BEGIN
  Select max(fycd) into pfycd from fymas ;
  
  SELECT SUBDEPTCD INTO VSUBDEPTCD 
  FROM EMPMAS_FY 
  WHERE COMPCD=PCOMPCD AND EMPCD=PEMPCD AND FYCD=PFYCD;
  RETURN VSUBDEPTCD;
EXCEPTION
  WHEN OTHERS THEN 
  RETURN VSUBDEPTCD;
END;
/
grant execute on GETSUBDEPTCD to NEWMFG;





CREATE OR REPLACE FUNCTION GET_CHANGE(PCOMPCD NUMBER,PEMP_REFNO VARCHAR2 ,PEMPCD VARCHAR2) RETURN VARCHAR2 IS
  PLENGTH NUMBER;
  VCHAR   VARCHAR2(20);
  TOTEXT  VARCHAR2(20);
  TP VARCHAR2(20);
  EMPREFNO_TP VARCHAR2(20);
  P_TOTPAY NUMBER;
  A  VARCHAR2(20);
BEGIN
IF PEMP_REFNO IS NULL AND PEMPCD IS NOT NULL THEN
   SELECT EMP_REFNO,TOTPAY INTO A,P_TOTPAY FROM EMPMAS WHERE COMPCD=PCOMPCD AND EMPCD=PEMPCD;
  EMPREFNO_TP := A;
ELSE
  EMPREFNO_TP := PEMP_REFNO;
END IF;
 IF EMPREFNO_TP IS NULL  THEN 
     RETURN P_TOTPAY;
END IF;
     
  PLENGTH := LENGTH (EMPREFNO_TP);
  FOR I IN 1..PLENGTH
      LOOP
        VCHAR := SUBSTR(EMPREFNO_TP,I,1);
       IF  VCHAR='G' THEN
           TOTEXT :='1';
       ELSIF VCHAR='W' THEN
           TOTEXT :='2';
       ELSIF VCHAR='L' THEN
           TOTEXT :='3';
       ELSIF VCHAR='B' THEN
           TOTEXT :='4';
       ELSIF VCHAR='K' THEN
           TOTEXT :='5';
       ELSIF VCHAR='A' THEN
           TOTEXT :='6';
       ELSIF VCHAR='U' THEN
           TOTEXT :='7';
       ELSIF VCHAR='M' THEN
           TOTEXT :='8';
       ELSIF VCHAR='Y' THEN
           TOTEXT :='9';
       ELSIF VCHAR='T' THEN
           TOTEXT :='0';
      END IF;
           TP := RTRIM(LTRIM(TP)) ||''|| RTRIM(LTRIM(TOTEXT));
      END LOOP;

     RETURN TP ;

END ;
/


CREATE OR REPLACE FUNCTION get_osuser(ptype varchar2) RETURN  char IS
BEGIN
  return sys_context('USERENV',ptype);
END;
/



create or replace procedure Rectified_Salary
  (pcomp number, PSALMONTH VARCHAR2, pemp varchar2, pwd number, ppd number,
   psal in out saltran%rowtype) is

  cursor cur_slab is select nvl (basic,0) basic,nvl (da,0) da,nvl (hra,0) hra,nvl (mediremb,0) mediremb,
   nvl (transport,0) transport,nvl (child,0) child,nvl (pf,'N') pf, nvl (esic,'N') esic,
   bankno,banknm,GETFLOORCD(COMPCD,EMPCD) floor,getdeptcd(compcd,empcd) deptcd,totpay realsal from empmas
  where compcd = pcomp and empcd = pemp ;

  cursor cur_govt is select * from govtrules where compcd = pcomp;

  slab  			CUR_SLAB%rowtype ;
  rules 			CUR_GOVT%rowtype ;
  ppt 				NUMBER;
  OLD_PT			NUMBER;
  OLD_GROSS		NUMBER;
  NEW_GROSS 	NUMBER;
begin
  open cur_govt ; fetch cur_govt into rules ; close cur_govt ;
  open cur_slab ; fetch cur_slab into slab ; close cur_slab ;

  psal.bankno := slab.bankno ;
  psal.banknm := slab.banknm ;
  psal.floorcd := slab.floor ;
  psal.deptcd := slab.deptcd ;

  psal.basic := nvl (slab.basic,0) ;
  psal.da := nvl (slab.da,0) ;
  psal.hra := nvl (slab.hra,0) ;
  psal.mediremb := nvl (slab.mediremb,0) ;
  psal.transport := nvl (slab.transport,0) ;

  if psal.saltype not in ('N') then
    psal.ea := nvl (slab.child,0) ;
  else
    psal.ea := 0;
  end if;

  psal.realsal := nvl (slab.realsal,0) ;
  psal.basics := nvl (slab.basic,0) + nvl (slab.da,0) ;
  psal.allowances := nvl (slab.hra,0)+ nvl (slab.mediremb,0) + nvl (slab.transport,0) + nvl (slab.child,0) ;


  psal.ebasic := round (nvl (slab.basic,0) * nvl (ppd,0) / nvl (pwd,0)) ;
  psal.eda := round (nvl (slab.da,0) * nvl (ppd,0) / nvl (pwd,0)) ;
  psal.ehra := round (nvl (slab.hra,0) * nvl (ppd,0) / nvl (pwd,0)) ;
  psal.emediremb := round ( nvl (slab.mediremb,0)* nvl(ppd,0) / nvl(pwd,0)) ;
  psal.etransport := round (nvl (slab.transport,0) * nvl (ppd,0) / nvl (pwd,0));

  if psal.saltype NOT IN ('N') then
     psal.eea := nvl (slab.child,0);
  else
     psal.eea := 0;
  end if;

  psal.ebasics := nvl (psal.ebasic,0) + nvl (psal.eda,0) ;
  psal.eallowances := nvl (psal.ehra,0)+ nvl (psal.emediremb,0) + nvl (psal.etransport,0) + nvl (psal.eea,0) ;

  psal.grosssal := psal.ebasic + psal.eda + psal.ehra + psal.emediremb + psal.etransport + psal.eea ;

  if slab.pf = 'Y' or psal.basics <= rules.pflimit then
    psal.pfgross := least (psal.ebasics,rules.pflimit) ;
  else
    psal.pfgross := 0 ;
  end if ;

    psal.emppfper := rules.emppfper ;
    psal.comptotpfper := rules.comptotpfper ;
    psal.compfpfper := rules.compfpfper ;
    psal.comppfper := rules.comppfper ;
    psal.empesicper := rules.empesicper ;
    psal.compesicper := rules.compesicper ;

    psal.emppf := round (psal.pfgross * rules.emppfper / 100) ;

    psal.comptotpf := round (psal.pfgross * rules.comptotpfper / 100) ;

    psal.comppf := round (psal.pfgross * rules.comppfper / 100) ;

    psal.compfpf := nvl (psal.comptotpf,0) - nvl (psal.comppf,0);



  if slab.esic = 'Y' or (slab.basic + slab.da + slab.transport
                         + slab.child + slab.hra + slab.mediremb ) <= rules.esiclimit then
    psal.esicgross := nvl (psal.ebasic,0) + nvl (psal.eda,0) +
                      nvl (psal.etransport,0) +
                      nvl (psal.ea,0) + nvl (psal.ehra,0) + nvl(psal.emediremb,0) ;

  else
    psal.esicgross := 0 ;
  end if ;
    psal.empesic := ceil (psal.esicgross * rules.empesicper / 100) ;

    psal.compesic := ceil (psal.esicgross * rules.compesicper / 100) ;

  BEGIN
  	SELECT PT,GROSSSAL INTO OLD_PT,OLD_GROSS
  	FROM SALTRAN WHERE COMPCD=PCOMP AND SALMONTH=PSALMONTH AND SALTYPE='S' AND EMPCD=PEMP ;
  EXCEPTION
  	WHEN NO_DATA_FOUND THEN
  	OLD_PT	:=0; 
  	OLD_GROSS := 0;
  END;

  NEW_GROSS := NVL(OLD_GROSS,0) + NVL(PSAL.GROSSSAL,0) ;
  
  BEGIN
  	select max(pt) into ppt from ptslab where compcd=pcomp and NEW_GROSS between fgrosssal and tgrosssal;
  END;
 
  PSAL.PT := NVL(PPT,0) - NVL(OLD_PT,0) ;
 
  
 	--psal.pt:=ppt;
  
  psal.totded := psal.emppf + psal.empesic + psal.pt + nvl (psal.tds,0)  ;
  psal.netpay := psal.grosssal - psal.totded - nvl (psal.advance,0) ;
end ;
/



CREATE OR REPLACE PACKAGE BODY PKG_PARAM AS
  FDATE         DATE;
  TDATE         DATE;
  PEMPCD       VARCHAR2(20);

  PROCEDURE SET_FDATE(P_FDATE IN DATE) IS
  BEGIN
    FDATE  := P_FDATE;
  END;

  PROCEDURE SET_TDATE(P_TDATE IN DATE) IS
  BEGIN
    TDATE  := P_TDATE;
  END;

  PROCEDURE SET_PEMPCD   (P_EMPCD IN VARCHAR2) IS
  BEGIN
    PEMPCD := P_EMPCD;
  END;


  FUNCTION GET_FDATE  RETURN DATE IS
  BEGIN
    RETURN FDATE;
  END;

  FUNCTION GET_TDATE  RETURN DATE IS
  BEGIN
    RETURN TDATE;
  END;

  FUNCTION GET_PEMPCD  RETURN VARCHAR2 IS
  BEGIN
    RETURN PEMPCD;
  END;

END PKG_PARAM;
/





CREATE OR REPLACE TRIGGER LOCKSALTRAN BEFORE INSERT OR DELETE OR UPDATE ON SALTRAN REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW  
DECLARE
  abc number(1);
BEGIN
  select count(0) into abc from locksaltran where  compcd=:new.compcd and lockmonth=:new.salmonth;

  IF nvl(abc,0) > 0 THEN
    RAISE_application_error(-20000,'DATA LOCKED FOR THIS MONTH');
  END IF;
EXCEPTION 
  WHEN OTHERS THEN 
  raise_application_error(sqlcode,SQLERRM);
END;
/



/*
CREATE TABLE EMP_DEPTDESG
(
DESGCD    	NUMBER(5),
SUBDEPTCD 	NUMBER(5),
DEPTCD    	NUMBER(5)
);
*/



--############################################################################################################################
--23/10/2024

CREATE OR REPLACE FUNCTION GETUSERDMLSTATUS(PUSER USERMAS.USERNAME%TYPE,PMENUCD USERMENU.MENUCD%TYPE,PFLAG VARCHAR2) RETURN VARCHAR2 IS
  VSTATUS VARCHAR2(1);
begin
  IF PUSER NOT IN ('ADMIN','PARESH') THEN
   IF pflag = 'INSERT' THEN
     SELECT NVL(INSERT_ALLOWED,'N') INTO VSTATUS FROM USERMENU WHERE USERNAME = PUSER AND MENUCD = PMENUCD ;
   ELSIF pflag = 'UPDATE' THEN
     SELECT NVL(UPDATE_ALLOWED,'N') INTO VSTATUS FROM USERMENU WHERE USERNAME = PUSER AND MENUCD = PMENUCD ;
   ELSIF pflag = 'DELETE' THEN
     SELECT NVL(DELETE_ALLOWED,'N') INTO VSTATUS FROM USERMENU WHERE USERNAME = PUSER AND MENUCD = PMENUCD ;
   ELSE
     VSTATUS := 'N' ;
   END IF;
  ELSE
   VSTATUS := 'Y' ;
  END IF;

  RETURN VSTATUS ;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  RETURN 'N' ;
END;
/



CREATE OR REPLACE FUNCTION GET_TERMINAL RETURN VARCHAR2 IS
BEGIN
 RETURN sys_context('USERENV', 'TERMINAL');
END;
/


 
CREATE OR REPLACE FUNCTION GET_IP RETURN VARCHAR2 IS
BEGIN
 RETURN sys_context('USERENV', 'IP_ADDRESS');
END;
/

 
--23/10/2024 
CREATE FUNCTION GETUSERLEVEL (PUSERNAME USERMAS.USERNAME%TYPE) RETURN VARCHAR2 IS
  VUSERLEVEL USERMAS.USERLEVEL%TYPE;
BEGIN
  SELECT USERLEVEL INTO VUSERLEVEL FROM USERMAS WHERE USERNAME = UPPER(PUSERNAME);
  RETURN VUSERLEVEL;
EXCEPTION 
  WHEN OTHERS THEN 
  RETURN '-'; 
END;



--24/10/2024
CREATE FUNCTION GETMODULEDMLSTATUS(PMENUCD USERMENU.MENUCD%TYPE,PFLAG VARCHAR2) RETURN VARCHAR2 IS
  VSTATUS VARCHAR2(1);
BEGIN
  IF PFLAG = 'INSERT' THEN
    SELECT NVL(INSERTABLE,'N') INTO VSTATUS FROM MENUMAS WHERE MENUCD = PMENUCD;
  ELSIF PFLAG = 'UPDATE' THEN
    SELECT NVL(UPDATEABLE,'N') INTO VSTATUS FROM MENUMAS WHERE MENUCD = PMENUCD;
  ELSIF PFLAG = 'DELETE' THEN
    SELECT NVL(DELETEABLE,'N') INTO VSTATUS FROM MENUMAS WHERE MENUCD = PMENUCD;
  ELSE
    VSTATUS := 'N' ;
  END IF;

  RETURN VSTATUS ;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
  RETURN 'N' ;
END;


--25/10/2024
CREATE OR REPLACE FUNCTION GETORDMENU(PMENUCD VARCHAR2) RETURN VARCHAR2 IS
  VORDER VARCHAR2(20);
BEGIN
  SELECT ORDMENU INTO VORDER FROM MENUMAS WHERE MENUCD = PMENUCD;
  RETURN VORDER;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 RETURN NULL;
END;
/


CREATE OR REPLACE PROCEDURE LOG_LOGIN (P_LOGIN_PROG VARCHAR2, P_USER VARCHAR2, P_PASS VARCHAR2, P_FLAG VARCHAR2, P_MACHINE VARCHAR2, P_IP VARCHAR2, P_MSG VARCHAR2) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO LOG_LOGIN_USER (LOGIN_DATE, LOGIN_PROG, ATTEMPT_USER, ATTEMPT_PASS, ATTEMPT_FLAG, MACHINENM, MACHINEIP, MSG)
  VALUES (SYSDATE, P_LOGIN_PROG, P_USER, P_PASS, P_FLAG, P_MACHINE, P_IP, P_MSG);

  COMMIT;
END;
/

--25/10/2024 
CREATE OR REPLACE PROCEDURE LOG_SOFT_USE(P_EMPCD        LOG_SOFT_USAGE.EMPCD%TYPE,
                                         P_USERNAME     LOG_SOFT_USAGE.USERNAME%TYPE,
                                         P_LOCATION     LOG_SOFT_USAGE.LOCATION%TYPE,
                                         P_MACHINENM    LOG_SOFT_USAGE.MACHINENM%TYPE,
                                         P_MACHINEIP    LOG_SOFT_USAGE.MACHINEIP%TYPE,
                                         P_MENUCD       LOG_SOFT_USAGE.MENUCD%TYPE,
                                         P_MENUGROUP    LOG_SOFT_USAGE.MENUGROUP%TYPE,
                                         P_MENUNM       LOG_SOFT_USAGE.MENUNM%TYPE,
                                         P_MENUFLAG     LOG_SOFT_USAGE.MENUFLAG%TYPE,
                                         POUT_ERROR     OUT VARCHAR2) IS

    V_MENUNM                   MENUMAS.MENUNM%TYPE;
    V_MENUGROUP                MENUMAS.MENUGROUP%TYPE;
BEGIN
  IF P_MENUNM IS NULL THEN
    SELECT MENUNM,MENUGROUP INTO V_MENUNM, V_MENUGROUP FROM MENUMAS WHERE MENUCD = P_MENUCD;
  ELSE
    V_MENUNM    := P_MENUNM;
    V_MENUGROUP := P_MENUGROUP;
  END IF;
  --
  INSERT INTO LOG_SOFT_USAGE
  (EMPCD,MACHINENM, MACHINEIP, USERNAME, RUNDATE, RUNTIME, LOCATION, MENUCD, MENUGROUP, MENUNM, MENUFLAG)
  VALUES
  (P_EMPCD,UPPER(P_MACHINENM), P_MACHINEIP, UPPER(P_USERNAME), TRUNC(SYSDATE), TO_CHAR(SYSDATE, 'HH24:MI'), NULL, P_MENUCD, UPPER(V_MENUGROUP), UPPER(V_MENUNM), P_MENUFLAG);
  --
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
  ROLLBACK;
  POUT_ERROR := SQLERRM;
END LOG_SOFT_USE;
/




--new procedure - copied from sales
create or replace procedure log_soft_use(P_EMPCD        LOG_SOFT_USAGE.EMPCD%TYPE,
                                         P_USERNAME     LOG_SOFT_USAGE.USERNAME%TYPE,
                                         P_MACHINENM    LOG_SOFT_USAGE.MACHINENM%TYPE,
                                         P_MACHINEIP    LOG_SOFT_USAGE.MACHINEIP%TYPE,
                                         P_MENUCD       LOG_SOFT_USAGE.MENUCD%TYPE
                                         ) IS

    V_MENUNM                   MENUMAS.MENUNM%TYPE;
    V_MENUGROUP                MENUMAS.MENUGROUP%TYPE;
BEGIN
  SELECT MENUNM, MENUGROUP INTO V_MENUNM, V_MENUGROUP FROM MENUMAS WHERE MENUCD = P_MENUCD;
  --
  INSERT INTO LOG_SOFT_USAGE (EMPCD, USERNAME, MACHINENM, MACHINEIP,  RUNDATE, MENUCD, MENUGROUP, MENUNM)
  VALUES (P_EMPCD, P_USERNAME, P_MACHINENM, P_MACHINEIP,  SYSDATE, P_MENUCD, V_MENUGROUP, V_MENUNM);
  --
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
  NULL;
END log_soft_use;

--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

--26/11/2024 - HISTORY OF EMPMAS 
CREATE OR REPLACE TRIGGER TRG_AU_EMPMAS
  AFTER UPDATE OR DELETE ON EMPMAS
  FOR EACH ROW
DECLARE
  V_DML_FLAG  VARCHAR2(20);
BEGIN
  V_DML_FLAG := CASE WHEN UPDATING THEN 'UPDATE' WHEN DELETING THEN 'DELETE' END;

  INSERT INTO HIS_EMPMAS
    (COMPCD,
     EMPCD,
     EMPNO,
     EMPNM,
     SHORTNM,
     FIRSTNM,
     MIDDLENM,
     LASTNM,
     DESGCD,
     DEPTCD,
     JOINDATE,
     BIRTHDATE,
     RESIGNDATE,
     NOTARYDATE,
     CARDISSDATE,
     GENDER,
     BLOOD_GROUP,
     ADD1,
     ADD2,
     ADD3,
     CITY,
     STATE,
     CONTACTNO1,
     CONTACTNO2,
     PADD1,
     PADD2,
     PADD3,
     PCITY,
     PSTATE,
     REFERENCE_BY,
     QUALIFICATION,
     PFNO,
     UANNO,
     PF_FLAG,
     PF_JOINDATE,
     PF_PCT,
     ESIC_FLAG,
     ESICNO,
     ESIC_BRANCH,
     ESIC_PCT,
     PT_FLAG,
     MARITAL_STATUS,
     NO_OF_CHILD,
     STUDYING_CHILD,
     PHY_DISABILITY,
     PHY_CERTY_DATE,
     ACNO,
     BANKNM,
     BANK_BRANCH,
     AADHARNO,
     PASSPORTNO,     
     PANNO,
     VOTERID,
     BASIC,
     DA,
     HRA,
     EA,
     TA,
     MEDIREMB,
     REALSAL,
     HANDICAPPED,
     SENIOR_CITIZEN,
     STATUS,
     REMARK,
     DML_FLAG,
     DML_USER,
     DML_DATE,
     DML_TERMINAL,
     DML_IP
     )
  VALUES
    (:OLD.COMPCD,
     :OLD.EMPCD,
     :OLD.EMPNO,
     DECODE(:OLD.EMPNM, :NEW.EMPNM, NULL, :OLD.EMPNM),
     DECODE(:OLD.SHORTNM, :NEW.SHORTNM, NULL, :OLD.SHORTNM),
     DECODE(:OLD.FIRSTNM, :NEW.FIRSTNM, NULL, :OLD.FIRSTNM),
     DECODE(:OLD.MIDDLENM, :NEW.MIDDLENM, NULL, :OLD.MIDDLENM),
     DECODE(:OLD.LASTNM, :NEW.LASTNM, NULL, :OLD.LASTNM),
     DECODE(:OLD.DESGCD, :NEW.DESGCD, NULL, :OLD.DESGCD),
     DECODE(:OLD.DEPTCD, :NEW.DEPTCD, NULL, :OLD.DEPTCD),
     DECODE(:OLD.JOINDATE, :NEW.JOINDATE, NULL, :OLD.JOINDATE),
     DECODE(:OLD.BIRTHDATE, :NEW.BIRTHDATE, NULL, :OLD.BIRTHDATE),
     DECODE(:OLD.RESIGNDATE, :NEW.RESIGNDATE, NULL, :OLD.RESIGNDATE),
     DECODE(:OLD.NOTARYDATE, :NEW.NOTARYDATE, NULL, :OLD.NOTARYDATE),
     DECODE(:OLD.CARDISSDATE, :NEW.CARDISSDATE, NULL, :OLD.CARDISSDATE),
     DECODE(:OLD.GENDER, :NEW.GENDER, NULL, :OLD.GENDER),
     DECODE(:OLD.BLOOD_GROUP, :NEW.BLOOD_GROUP, NULL, :OLD.BLOOD_GROUP),
     DECODE(:OLD.ADD1, :NEW.ADD1, NULL, :OLD.ADD1),
     DECODE(:OLD.ADD2, :NEW.ADD2, NULL, :OLD.ADD2),
     DECODE(:OLD.ADD3, :NEW.ADD3, NULL, :OLD.ADD3),
     DECODE(:OLD.CITY, :NEW.CITY, NULL, :OLD.CITY),
     DECODE(:OLD.STATE, :NEW.STATE, NULL, :OLD.STATE),
     DECODE(:OLD.CONTACTNO1, :NEW.CONTACTNO1, NULL, :OLD.CONTACTNO1),
     DECODE(:OLD.CONTACTNO2, :NEW.CONTACTNO2, NULL, :OLD.CONTACTNO2),
     DECODE(:OLD.PADD1, :NEW.PADD1, NULL, :OLD.PADD1),
     DECODE(:OLD.PADD2, :NEW.PADD2, NULL, :OLD.PADD2),
     DECODE(:OLD.PADD3, :NEW.PADD3, NULL, :OLD.PADD3),
     DECODE(:OLD.PCITY, :NEW.PCITY, NULL, :OLD.PCITY) ,
     DECODE(:OLD.PSTATE, :NEW.PSTATE, NULL, :OLD.PSTATE),
     DECODE(:OLD.REFERENCE_BY, :NEW.REFERENCE_BY, NULL, :OLD.REFERENCE_BY),
     DECODE(:OLD.QUALIFICATION, :NEW.QUALIFICATION, NULL, :NEW.QUALIFICATION),
     DECODE(:OLD.PFNO, :NEW.PFNO, NULL, :OLD.PFNO),
     DECODE(:OLD.UANNO, :NEW.UANNO, NULL, :OLD.UANNO),
     DECODE(:OLD.PF_FLAG, :NEW.PF_FLAG, NULL, :OLD.PF_FLAG),
     DECODE(:OLD.PF_JOINDATE, :NEW.PF_JOINDATE, NULL, :OLD.PF_JOINDATE),
     DECODE(:OLD.PF_PCT, :NEW.PF_PCT, NULL, :OLD.PF_PCT),
     DECODE(:OLD.ESIC_FLAG, :NEW.ESIC_FLAG, NULL, :OLD.ESIC_FLAG),
     DECODE(:OLD.ESICNO, :NEW.ESICNO, NULL, :OLD.ESICNO),
     DECODE(:OLD.ESIC_BRANCH, :NEW.ESIC_BRANCH, NULL, :OLD.ESIC_BRANCH),
     DECODE(:OLD.ESIC_PCT, :NEW.ESIC_PCT, NULL, :OLD.ESIC_PCT),
     DECODE(:OLD.PT_FLAG, :NEW.PT_FLAG, NULL, :OLD.PT_FLAG),
     DECODE(:OLD.MARITAL_STATUS, :NEW.MARITAL_STATUS, NULL, :OLD.MARITAL_STATUS),
     DECODE(:OLD.NO_OF_CHILD, :NEW.NO_OF_CHILD, NULL, :OLD.NO_OF_CHILD),
     DECODE(:OLD.STUDYING_CHILD, :NEW.STUDYING_CHILD, NULL, :OLD.STUDYING_CHILD),
     DECODE(:OLD.PHY_DISABILITY, :NEW.PHY_DISABILITY, NULL, :OLD.PHY_DISABILITY),
     DECODE(:OLD.PHY_CERTY_DATE, :NEW.PHY_CERTY_DATE, NULL, :OLD.PHY_CERTY_DATE),
     DECODE(:OLD.ACNO, :NEW.ACNO, NULL, :OLD.ACNO),
     DECODE(:OLD.BANKNM, :NEW.BANKNM, NULL, :OLD.BANKNM),
     DECODE(:OLD.BANK_BRANCH, :NEW.BANK_BRANCH, NULL, :OLD.BANK_BRANCH),
     DECODE(:OLD.AADHARNO, :NEW.AADHARNO, NULL, :OLD.AADHARNO),
     DECODE(:OLD.PASSPORTNO, :NEW.PASSPORTNO, NULL, :OLD.PASSPORTNO),
     DECODE(:OLD.PANNO, :NEW.PANNO, NULL, :OLD.PANNO),
     DECODE(:OLD.VOTERID, :NEW.VOTERID, NULL, :OLD.VOTERID),
     DECODE(:OLD.BASIC, :NEW.BASIC, NULL, :OLD.BASIC),
     DECODE(:OLD.DA, :NEW.DA, NULL, :OLD.DA),
     DECODE(:OLD.HRA, :NEW.HRA, NULL, :OLD.HRA),
     DECODE(:OLD.EA, :NEW.EA, NULL, :OLD.EA),
     DECODE(:OLD.TA, :NEW.TA, NULL, :OLD.TA),
     DECODE(:OLD.MEDIREMB, :NEW.MEDIREMB, NULL, :OLD.MEDIREMB),
     DECODE(:OLD.REALSAL, :NEW.REALSAL, NULL, :OLD.REALSAL),
     DECODE(:OLD.HANDICAPPED, :NEW.HANDICAPPED, NULL, :OLD.HANDICAPPED),
     DECODE(:OLD.SENIOR_CITIZEN, :NEW.SENIOR_CITIZEN, NULL, :OLD.SENIOR_CITIZEN),
     DECODE(:OLD.STATUS, :NEW.STATUS, NULL, :OLD.STATUS),
     DECODE(:OLD.REMARK, :NEW.REMARK, NULL, :OLD.REMARK) ,
     V_DML_FLAG,
     :NEW.CUSER,
     SYSDATE,
     GET_TERMINAL,
     GET_IP
     );

END TRG_AU_EMPMAS;



--28/11/2024

CREATE OR REPLACE TRIGGER AUD_SALTRAN AFTER UPDATE OR DELETE ON SALTRAN FOR EACH ROW
DECLARE
    V_DML_FLAG VARCHAR2(10);
BEGIN
  V_DML_FLAG := CASE WHEN UPDATING THEN 'UPDATE' WHEN DELETING THEN 'DELETE' END;

   INSERT INTO HIS_SALTRAN
    (COMPCD,
     FYCD,
     DEPTCD,
     FLOORCD,
     EMPCD,
     EMP_TYPE,
     SALTYPE,
     SALMONTH,
     PAYDATE,
     PAYMODE,
     WD,
     PD,
     TD,
     LPD,
     REALSAL,
     BASIC,
     DA,
     HRA,
     TA,
     EA,
     MEDIREMB,
     BASICS,
     ALLOWANCES,
     PERDAYSAL,
     EBASIC,
     EDA,
     EHRA,
     ETA,
     EEA,
     EMEDIREMB,
     EBASICS,
     EALLOWANCES,
     PFGROSS,
     ESICGROSS,
     COMPEPF_PCT,
     COMPEPS_PCT,
     COMPPF_PCT,
     COMPEPF,
     COMPEPS,
     COMPPF,
     COMPESIC_PCT,
     COMPESIC,
     EMPEPF_PCT,
     EMPEPS_PCT,
     EMPPF_PCT,
     EMPEPF,
     EMPEPS,
     EMPPF,
     EMPESIC_PCT,
     EMPESIC,
     PT,
     EMPLWF,
     COMPLWF,
     TOTDEDUCT,
     ADVANCE,
     INCENTIVE,
     PENALTY,
     NETPAY,
     ACNO,
     BANKNM,
     TDS,
     SURCHARGE,
     CESS,
     TOTTDS,
     GROSSSAL,
     BONUSQUALAMT,
     BONUSEBASICS,
     LEAVEPERDAYWGS,
     EUSER,
     ETERMINAL,
     EDATE,
     DML_FLAG,
     DML_USER,
     DML_DATE,
     DML_TERMINAL
     )
  VALUES
    (:OLD.COMPCD,
     :OLD.FYCD,
     :OLD.DEPTCD,
     :OLD.FLOORCD,
     :OLD.EMPCD,
     :OLD.EMP_TYPE,
     :OLD.SALTYPE,
     :OLD.SALMONTH,
     DECODE(:OLD.PAYDATE, :NEW.PAYDATE, NULL, :OLD.PAYDATE),
     DECODE(:OLD.PAYMODE, :NEW.PAYMODE, NULL, :OLD.PAYMODE),
     DECODE(:OLD.WD, :NEW.WD, NULL, :OLD.WD),
     DECODE(:OLD.PD, :NEW.PD, NULL, :OLD.PD),
     DECODE(:OLD.TD, :NEW.TD, NULL, :OLD.TD),
     DECODE(:OLD.LPD, :NEW.LPD, NULL, :OLD.LPD),
     DECODE(:OLD.REALSAL, :NEW.REALSAL, NULL, :OLD.REALSAL),
     DECODE(:OLD.BASIC, :NEW.BASIC, NULL, :OLD.BASIC),
     DECODE(:OLD.DA, :NEW.DA, NULL, :OLD.DA),
     DECODE(:OLD.HRA, :NEW.HRA, NULL, :OLD.HRA),
     DECODE(:OLD.TA, :NEW.TA, NULL, :OLD.TA),
     DECODE(:OLD.EA, :NEW.EA, NULL, :OLD.EA),
     DECODE(:OLD.MEDIREMB, :NEW.MEDIREMB, NULL, :OLD.MEDIREMB),
     DECODE(:OLD.BASICS, :NEW.BASICS, NULL, :OLD.BASICS),
     DECODE(:OLD.ALLOWANCES, :NEW.ALLOWANCES, NULL, :OLD.ALLOWANCES),
     DECODE(:OLD.PERDAYSAL, :NEW.PERDAYSAL, NULL, :OLD.PERDAYSAL),
     DECODE(:OLD.EBASIC, :NEW.EBASIC, NULL, :OLD.EBASIC),
     DECODE(:OLD.EDA, :NEW.EDA, NULL, :OLD.EDA),
     DECODE(:OLD.EHRA, :NEW.EHRA, NULL, :OLD.EHRA),
     DECODE(:OLD.ETA, :NEW.ETA, NULL, :OLD.ETA),
     DECODE(:OLD.EEA, :NEW.EEA, NULL, :OLD.EEA),
     DECODE(:OLD.EMEDIREMB, :NEW.EMEDIREMB, NULL, :OLD.EMEDIREMB),
     DECODE(:OLD.EBASICS, :NEW.EBASICS, NULL, :OLD.EBASICS),
     DECODE(:OLD.EALLOWANCES, :NEW.EALLOWANCES, NULL, :OLD.EALLOWANCES),
     DECODE(:OLD.PFGROSS, :NEW.PFGROSS, NULL, :OLD.PFGROSS),
     DECODE(:OLD.ESICGROSS, :NEW.ESICGROSS, NULL, :OLD.ESICGROSS),
     DECODE(:OLD.COMPEPF_PCT, :NEW.COMPEPF_PCT, NULL, :OLD.COMPEPF_PCT),
     DECODE(:OLD.COMPEPS_PCT, :NEW.COMPEPS_PCT, NULL, :OLD.COMPEPS_PCT),
     DECODE(:OLD.COMPPF_PCT, :NEW.COMPPF_PCT, NULL, :OLD.COMPPF_PCT),
     DECODE(:OLD.COMPEPF, :NEW.COMPEPF, NULL, :OLD.COMPEPF),
     DECODE(:OLD.COMPEPS, :NEW.COMPEPS, NULL, :OLD.COMPEPS),
     DECODE(:OLD.COMPPF, :NEW.COMPPF, NULL, :OLD.COMPPF),
     DECODE(:OLD.COMPESIC_PCT, :NEW.COMPESIC_PCT, NULL, :OLD.COMPESIC_PCT),
     DECODE(:OLD.COMPESIC, :NEW.COMPESIC, NULL, :OLD.COMPESIC),
     DECODE(:OLD.EMPEPF_PCT, :NEW.EMPEPF_PCT, NULL, :OLD.EMPEPF_PCT),
     DECODE(:OLD.EMPEPS_PCT, :NEW.EMPEPS_PCT, NULL, :OLD.EMPEPS_PCT),
     DECODE(:OLD.EMPPF_PCT, :NEW.EMPPF_PCT, NULL, :OLD.EMPPF_PCT),
     DECODE(:OLD.EMPEPF, :NEW.EMPEPF, NULL, :OLD.EMPEPF),
     DECODE(:OLD.EMPEPS, :NEW.EMPEPS, NULL, :OLD.EMPEPS),
     DECODE(:OLD.EMPPF, :NEW.EMPPF, NULL, :OLD.EMPPF),
     DECODE(:OLD.EMPESIC_PCT, :NEW.EMPESIC_PCT, NULL, :OLD.EMPESIC_PCT),
     DECODE(:OLD.EMPESIC, :NEW.EMPESIC, NULL, :OLD.EMPESIC),
     DECODE(:OLD.PT, :NEW.PT, NULL, :OLD.PT),
     DECODE(:OLD.EMPLWF, :NEW.EMPLWF, NULL, :OLD.EMPLWF),
     DECODE(:OLD.COMPLWF, :NEW.COMPLWF, NULL, :OLD.COMPLWF),
     DECODE(:OLD.TOTDEDUCT, :NEW.TOTDEDUCT, NULL, :OLD.TOTDEDUCT),
     DECODE(:OLD.ADVANCE, :NEW.ADVANCE, NULL, :OLD.ADVANCE),
     DECODE(:OLD.INCENTIVE, :NEW.INCENTIVE, NULL, :OLD.INCENTIVE),
     DECODE(:OLD.PENALTY, :NEW.PENALTY, NULL, :OLD.PENALTY),
     DECODE(:OLD.NETPAY, :NEW.NETPAY, NULL, :OLD.NETPAY),
     DECODE(:OLD.ACNO, :NEW.ACNO, NULL, :OLD.ACNO),
     DECODE(:OLD.BANKNM, :NEW.BANKNM, NULL, :OLD.BANKNM),
     DECODE(:OLD.TDS, :NEW.TDS, NULL, :OLD.TDS),
     DECODE(:OLD.SURCHARGE, :NEW.SURCHARGE, NULL, :OLD.SURCHARGE),
     DECODE(:OLD.CESS, :NEW.CESS, NULL, :OLD.CESS),
     DECODE(:OLD.TOTTDS, :NEW.TOTTDS, NULL, :OLD.TOTTDS),
     DECODE(:OLD.GROSSSAL, :NEW.GROSSSAL, NULL, :OLD.GROSSSAL),
     DECODE(:OLD.BONUSQUALAMT, :NEW.BONUSQUALAMT, NULL, :OLD.BONUSQUALAMT),
     DECODE(:OLD.BONUSEBASICS, :NEW.BONUSEBASICS, NULL, :OLD.BONUSEBASICS),
     DECODE(:OLD.LEAVEPERDAYWGS, :NEW.LEAVEPERDAYWGS, NULL, :OLD.LEAVEPERDAYWGS),
     :OLD.EUSER,
     :OLD.ETERMINAL,
     :OLD.EDATE,
     V_DML_FLAG,
     NULL, --PKG_MAS_DML.TRG_USER,
     SYSDATE,
     NULL --PKG_MAS_DML.TRG_TERMINAL
     );

END AUD_SALTRAN;
