/*
********************************************************************************************************************************
												Geração de Documentos na Av.Brasil
********************************************************************************************************************************
*/
--Conexão Lobo Jr.
--Buca parâmetro de mês aberto, em seguida fecha a conexão
select	M02_TX_PARAMETRO
from	materiais..MAT_M02_PARAMETROS 
where	M02_NR_PARAMETRO = 23
par_mesaberto$="202408"

--Conexão Av.Brasil
--Verifica se a geração automática de documentos já foi implantada
select	A01_TX_VALOR
from	APN_A01_PARAMETROS
where	A01_ID_PARAMETRO = 4
só gera documento se A01_TX_VALOR = S

--Conexão Av.Brasil
--Bloqueio entidades na Av.Brasil
/*
sistema: 		GDC
entidade: 		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/

/*
sistema: 		APN
entidade: 		ESTOQUE
modo bloqueio:	T
chave: 			
*/

--Conexão Av.Brasil
--Número do próximo documento a ser gerado
select	M02_TX_PARAMETRO
from	sybase..MAT_M02_PARAMETROS
where	M02_NR_PARAMETRO = 30
nr_seq& = M02_TX_PARAMETRO

--Conexão Av.Brasil
--Atualiza as contas contábeis atende e recebe na tabela de movimentações (APN_A18_MOVIMENTACOES) 
--que não estão preenchidas
--a)para as movimentações de processo atualiza de acordo com a tabela APN_A02_ALMOX_PROCES
--b)para as movimentações que não são de processos atualiza de acordo com o material na tabela de saldos (sybase..MAT_M29_SALDOS): somente empresas 1 e 21
execute APN_A06_SP_ATUALIZA_CONTAS_CCUSTO

--Conexão Av.Brasil
--Busca as movimentações
--Entrada de romaneio
SELECT	A09_TP_DOCUMENTO, A14_NR_ROMANEIO,CCUSTO_ATENDE='', CCUSTO_RECEBE=A02B.M07_CD_CCUSTO,
		CONTA_ATENDE='', CONTA_RECEBE=A18_NR_CONTA_RECEBE,
		PESO_LIQUIDO=sum(A18_NR_PESO_LIQUIDO),
		QTDE_EMB=sum(A18_NR_QTDE_EMBALAGEM),
		A18_DT_MOVIMENTO,A14.L03_CD_MATERIAL, M06_SG_UNIDADE,
		S02_CD_USUARIO_SYBASE=isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)),
		A18_VL_BAIXA
FROM 	apn..APN_A18_MOVIMENTACOES A18,
		apn..APN_A09_MOVIMENTOS A09,
		apn..APN_A14_ROMANEIOS A14,
		apn..APN_A15_ESTOQUES A15,
		apn..APN_A02_ALMOX_PROCES A02B,
		sybase..MAT_M15_MATERIAIS M15,
		senhas..S02_SEN_USUARIOS S02
WHERE	A18.A09_ID_MOVIMENTO = A09.A09_ID_MOVIMENTO
And 	A18.A18_ID_ALMOX_DESTINO = A02B.A02_ID_ALMOX_PROCES
And 	A18.A15_ID_ESTOQUE  = A15.A15_ID_ESTOQUE
And 	A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
And 	A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
And 	rtrim(A18.PP_TX_USER_STAMP) = rtrim(S02.S02_CD_USUARIO)
And 	A09_IN_MOVIMENTA_MATERIAIS = 'S'
And 	A18_ST_EXPORTA_MATERIAIS = 'N'
And 	A18_ST_LIBERADO_MATERIAIS = 'S'
And 	A18_ID_ALMOX_ORIGEM IS NULL
And 	A18.A09_ID_MOVIMENTO <> 1--baixa
GROUP BY A09_TP_DOCUMENTO, A02B.M07_CD_CCUSTO, A18_NR_CONTA_RECEBE, A18_DT_MOVIMENTO, A14.L03_CD_MATERIAL, 
isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)),A14_NR_ROMANEIO, M06_SG_UNIDADE, A18_VL_BAIXA
UNION ALL
--Consumo
SELECT	A09_TP_DOCUMENTO, A14_NR_ROMANEIO,CCUSTO_ATENDE=A02A.M07_CD_CCUSTO, CCUSTO_RECEBE='',
		CONTA_ATENDE=A18_NR_CONTA_ATENDE, CONTA_RECEBE='',
		PESO_LIQUIDO=sum(A18_NR_PESO_LIQUIDO),
		QTDE_EMB=sum(A18_NR_QTDE_EMBALAGEM),
		A18_DT_MOVIMENTO,A14.L03_CD_MATERIAL, M06_SG_UNIDADE,
		S02_CD_USUARIO_SYBASE=isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)), 
		A18_VL_BAIXA
FROM	apn..APN_A18_MOVIMENTACOES A18,
		apn..APN_A09_MOVIMENTOS A09,
		apn..APN_A14_ROMANEIOS A14,
		apn..APN_A15_ESTOQUES A15,
		apn..APN_A02_ALMOX_PROCES A02A,
		sybase..MAT_M15_MATERIAIS M15,
		senhas..S02_SEN_USUARIOS S02
WHERE 	A18.A09_ID_MOVIMENTO = A09.A09_ID_MOVIMENTO
And 	A18.A18_ID_ALMOX_ORIGEM = A02A.A02_ID_ALMOX_PROCES
And 	A18.A15_ID_ESTOQUE  = A15.A15_ID_ESTOQUE
And 	A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
And 	A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
And 	rtrim(A18.PP_TX_USER_STAMP) = rtrim(S02.S02_CD_USUARIO)
And 	A09_IN_MOVIMENTA_MATERIAIS = 'S'
And 	A18_ST_EXPORTA_MATERIAIS = 'N'
And 	A18_ST_LIBERADO_MATERIAIS = 'S'    
And 	A18_ID_ALMOX_DESTINO IS NULL
And 	A18.A09_ID_MOVIMENTO <> 1--baixa
GROUP BY A09_TP_DOCUMENTO, A02A.M07_CD_CCUSTO, A18_NR_CONTA_ATENDE, A18_DT_MOVIMENTO, A14.L03_CD_MATERIAL, 
isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)), A14_NR_ROMANEIO, M06_SG_UNIDADE, A18_VL_BAIXA
UNION ALL
--Devoluções, transferências, Requisições e produção
SELECT	A09_TP_DOCUMENTO, A14_NR_ROMANEIO,CCUSTO_ATENDE=A02A.M07_CD_CCUSTO, CCUSTO_RECEBE=A02B.M07_CD_CCUSTO,
		CONTA_ATENDE=A18_NR_CONTA_ATENDE, CONTA_RECEBE=A18_NR_CONTA_RECEBE,
		PESO_LIQUIDO=sum(A18_NR_PESO_LIQUIDO),
		QTDE_EMB=sum(A18_NR_QTDE_EMBALAGEM),
		A18_DT_MOVIMENTO,A14.L03_CD_MATERIAL, M06_SG_UNIDADE,
		S02_CD_USUARIO_SYBASE=isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)),
		A18_VL_BAIXA
FROM 	apn..APN_A18_MOVIMENTACOES A18,
		apn..APN_A09_MOVIMENTOS A09,
		apn..APN_A14_ROMANEIOS A14,
		apn..APN_A15_ESTOQUES A15,
		apn..APN_A02_ALMOX_PROCES A02A,
		apn..APN_A02_ALMOX_PROCES A02B,
		sybase..MAT_M15_MATERIAIS M15,
		senhas..S02_SEN_USUARIOS S02
WHERE 	A18.A09_ID_MOVIMENTO = A09.A09_ID_MOVIMENTO
And 	A18.A18_ID_ALMOX_ORIGEM = A02A.A02_ID_ALMOX_PROCES
And 	A18.A18_ID_ALMOX_DESTINO = A02B.A02_ID_ALMOX_PROCES
And 	A18.A15_ID_ESTOQUE  = A15.A15_ID_ESTOQUE
And 	A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
And 	A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
And 	rtrim(A18.PP_TX_USER_STAMP) = rtrim(S02.S02_CD_USUARIO)
And 	A09_IN_MOVIMENTA_MATERIAIS = 'S'
And 	A18_ST_EXPORTA_MATERIAIS = 'N'
And 	A18_ST_LIBERADO_MATERIAIS = 'S'
And 	A18.A09_ID_MOVIMENTO <> 1--baixa
GROUP BY A09_TP_DOCUMENTO, A02A.M07_CD_CCUSTO, A02B.M07_CD_CCUSTO, A18_NR_CONTA_ATENDE, A18_NR_CONTA_RECEBE, A18_DT_MOVIMENTO,
A14.L03_CD_MATERIAL, isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)), A14_NR_ROMANEIO, M06_SG_UNIDADE, A18_VL_BAIXA
UNION ALL
--Baixa
SELECT	A11.A11_TP_DOCUMENTO, A14_NR_ROMANEIO,CCUSTO_ATENDE=A02A.M07_CD_CCUSTO, CCUSTO_RECEBE=A11_CD_CCUSTO_RECEBE,
		CONTA_ATENDE=A18_NR_CONTA_ATENDE, CONTA_RECEBE=A11_NR_CONTA_RECEBE,
		PESO_LIQUIDO=sum(A18_NR_PESO_LIQUIDO),
		QTDE_EMB=sum(A18_NR_QTDE_EMBALAGEM),
		A18_DT_MOVIMENTO,A14.L03_CD_MATERIAL, M06_SG_UNIDADE,
		S02_CD_USUARIO_SYBASE=isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)),
		A18_VL_BAIXA
FROM 	apn..APN_A18_MOVIMENTACOES A18,
		apn..APN_A09_MOVIMENTOS A09,
		apn..APN_A14_ROMANEIOS A14,
		apn..APN_A15_ESTOQUES A15,
		apn..APN_A02_ALMOX_PROCES A02A,
		apn..APN_A11_MOTIVOS_BAIXAS A11,
		sybase..MAT_M15_MATERIAIS M15,
		senhas..S02_SEN_USUARIOS S02
WHERE 	A18.A09_ID_MOVIMENTO = A09.A09_ID_MOVIMENTO
And 	A18.A18_ID_ALMOX_ORIGEM = A02A.A02_ID_ALMOX_PROCES
And 	A18.A15_ID_ESTOQUE  = A15.A15_ID_ESTOQUE
And 	A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
And 	A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
And 	rtrim(A18.PP_TX_USER_STAMP) = rtrim(S02.S02_CD_USUARIO)
And 	A18.A11_ID_MOTIVO = A11.A11_ID_MOTIVO
And 	A09_IN_MOVIMENTA_MATERIAIS = 'S'
And 	A11_IN_MOVIMENTA_MATERIAIS = 'S'
And 	A18_ST_EXPORTA_MATERIAIS = 'N'
And 	A18_ST_LIBERADO_MATERIAIS = 'S'
And 	A11.A11_ID_MOTIVO IS NOT NULL
And 	A18.A09_ID_MOVIMENTO = 1
GROUP BY A11.A11_TP_DOCUMENTO, A02A.M07_CD_CCUSTO, A18_NR_CONTA_ATENDE, A18_DT_MOVIMENTO, A14.L03_CD_MATERIAL, 
isnull(S02_CD_USUARIO_SYBASE,rtrim(S02.S02_CD_USUARIO)), A11_CD_CCUSTO_RECEBE , A11_NR_CONTA_RECEBE, A14_NR_ROMANEIO, 
M06_SG_UNIDADE, A18_VL_BAIXA
ORDER BY A09_TP_DOCUMENTO, A18_DT_MOVIMENTO, 3,4,5,6,2
/*
A09_TP_DOCUMENTO A14_NR_ROMANEIO CCUSTO_ATENDE CCUSTO_RECEBE CONTA_ATENDE CONTA_RECEBE PESO_LIQUIDO          QTDE_EMB    A18_DT_MOVIMENTO        L03_CD_MATERIAL M06_SG_UNIDADE S02_CD_USUARIO_SYBASE A18_VL_BAIXA
---------------- --------------- ------------- ------------- ------------ ------------ --------------------- ----------- ----------------------- --------------- -------------- --------------------- ---------------------
11               142628          9030          9102          140.40       141.41       453.26                96          2024-08-20 00:00:00     30625540        KG             PIX13                 NULL
11               75079           9030          9102          140.40       141.41       68.17                 15          2024-08-23 00:00:00     30628725        KG             PIX13                 NULL

(2 linhas afetadas)
*/
Cotacao@ = 0

--Conexão Av.Brasil
--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO
	--busca a empresa do centro de custo e conta atende
	select	distinct M30_CD_EMPRESA
	from	sybase..MAT_M29_SALDOS M29,sybase..MAT_M07_CENTROS_CUSTO M07
	where	M29.M07_CD_CCUSTO = '9030 '
	and		M29.M09_NR_CONTA  = '140.40'
	and 	M07.M07_TP_CCUSTO = 'C'
	and 	M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	union
	--busca a empresa do centro de custo e conta recebe
	select	distinct M30_CD_EMPRESA
	from	sybase..MAT_M29_SALDOS M29,sybase..MAT_M07_CENTROS_CUSTO M07
	where	M29.M07_CD_CCUSTO = '9102 '
	and		M29.M09_NR_CONTA  = '141.41'
	and 	M07.M07_TP_CCUSTO = 'C'
	and 	M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	
	Emp_M30% = M30_CD_EMPRESA

    material$ = rs("L03_CD_MATERIAL")
    TP_DOC% = rs("A09_TP_DOCUMENTO")
    NR_DOC& = rs("A14_NR_ROMANEIO")
	datadoc$ = rs("A18_DT_MOVIMENTO")
	
    'A data do documento não pode ser inferior ao mês aberto.
    'Se for, modifica a data para o primeiro dia aberto
    If Format$(rs("A18_DT_MOVIMENTO"), "yyyymmdd") < par_mesaberto$ & "01" Then
        datadoc$ = "01/" & Right(par_mesaberto$, 2) & "/" & Left(par_mesaberto$, 4)
    End If

    pix_usuario_sybase$ = Trim$(rs("S02_CD_USUARIO_SYBASE"))
    If rs("M06_SG_UNIDADE") = "KG" Then
        Qtde@ = Format(rs("PESO_LIQUIDO"), "0.0#")
    Else
        Qtde@ = Format(rs("QTDE_EMB"), "0.0#")
    End If

	Valor_Unit@ = IIf(IsNull(rs("A18_VL_BAIXA")), 0, Format(rs("A18_VL_BAIXA"), "0.0#"))
	
	CCAtende$ = IIf(IsNull(rs("CCUSTO_ATENDE")), "", rs("CCUSTO_ATENDE"))
	CCRecebe$ = IIf(IsNull(rs("CCUSTO_RECEBE")), "", rs("CCUSTO_RECEBE"))

	ContaAtende$ = IIf(IsNull(rs("CONTA_ATENDE")), "", rs("CONTA_ATENDE"))
	ContaRecebe$ = IIf(IsNull(rs("CONTA_RECEBE")), "", rs("CONTA_RECEBE"))	
	
	
--Conexão Av.Brasil		
--o agrupamento do documento é pelos materiais que possuem as mesmas informações:
--A09_TP_DOCUMENTO, CCUSTO_ATENDE, CCUSTO_RECEBE, CONTA_ATENDE, CONTA_RECEBE, S02_CD_USUARIO_SYBASE, A14_NR_ROMANEIO
--insere todos os materiais do documento na M48 e depois insere o documento na M47	
INSERT INTO sybase..MAT_M48_DOC_MATERIAIS_BAT 
(M47_NR_SEQUENCIAL,M48_NR_POSICAO,L03_CD_MATERIAL,L03_NR_DV,M06_SG_UNIDADE,M48_NR_QUANTIDADE,
M11_CD_CCUSTO_ATENDE,M11_NR_CONTA_ATENDE,M11_CD_CCUSTO_RECEBE,M11_NR_CONTA_RECEBE,M48_VL_UNITARIO_1,M48_VL_UNITARIO_2)
VALUES 
(
16550710,--nr_seq&=sybase..MAT_M02_PARAMETROS-M02_NR_PARAMETRO = 30
1,--sequencial do registro dentro do M47_NR_SEQUENCIAL
'30625540',--material
'9',--Calcula_DV(material$)
'KG',--M06_SG_UNIDADE
453.26,--Qtde
'9030 ',--ContaAtende
'140.40',--CCAtende
'9102 ',--ContaRecebe
'141.41'--CCRecebe
,0,--Valor_Unit
0--Valor_Unit*Cotacao
)

--Conexão Av.Brasil
INSERT INTO sybase..MAT_M47_DOCUMENTOS_BAT 
(M47_NR_SEQUENCIAL,M03_NR_NATUREZA,M47_NR_DOCUMENTO, M30_CD_EMPRESA,M47_DT_DIGITACAO,M47_DT_DOCUMENTO,
M27_CD_USUARIO,M47_TX_OBSERVACAO,M47_ST_VALOR, M47_VL_TOTAL_DOC,M47_ST_SITUACAO,M47_IN_REPROCESSO,
M47_NR_NF_FORNECEDOR,M47_ST_EXPORTADO,M47_CD_SISTEMA_ORIGEM)
VALUES
(
16550710,--nr_seq&=sybase..MAT_M02_PARAMETROS-M02_NR_PARAMETRO = 30
11,--TP_DOC
142628,--NR_DOC
1,--Emp_M30
'08/29/2024',--Now
'08/20/2024',--datadoc
'PIX13',--pix_usuario_sybase
'',--''
'N',--'N'
0,
'N',--'N'
'S',--'S'
'',--''
'N',--'N'
'APN'--'APN'
)

--Conexão Av.Brasil
--atualiza o parâmetro com o próximo número de documento
update	Sybase..MAT_M02_PARAMETROS
set		M02_tx_parametro = '16550711'
where	M02_NR_Parametro = 30

--Conexão Av.Brasil
update	apn..APN_A18_MOVIMENTACOES 
set		A18_ST_EXPORTA_MATERIAIS = 'S'
where	A18_ST_EXPORTA_MATERIAIS = 'N'
and		A18_ST_LIBERADO_MATERIAIS = 'S'

--Conexão Av.Brasil
--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--Conexão Av.Brasil
--Desbloqueio entidades na Av.Brasil	
/*
sistema: 		APN
entidade: 		ESTOQUE
modo bloqueio:	T
chave: 			(vazio)
*/



/*
********************************************************************************************************************************
									Exportação dos Documentos para Lobo Jr.
********************************************************************************************************************************
*/

--Conexão Av.Brasil
--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO

--Conexão Lobo Jr.
--Bloqueio entidade na Lobo Jr.
/*
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/

--Conexão Lobo Jr.
--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO

--Conexão Av.Brasil
--Apaga na Av.Brasil os documentos gerados e exportados de 3 meses atrás
DELETE	sybase..MAT_M48_DOC_MATERIAIS_BAT 
FROM 	sybase..MAT_M48_DOC_MATERIAIS_BAT M48, 
		sybase..MAT_M47_DOCUMENTOS_BAT M47 
WHERE 	M47.M47_NR_SEQUENCIAL = M48.M47_NR_SEQUENCIAL 
AND 	M47_ST_EXPORTADO = 'S' 
AND 	M47_DT_DIGITACAO <= DATEADD(MONTH,-3,M47_DT_DIGITACAO) 

--Conexão Av.Brasil
DELETE	sybase..MAT_M47_DOCUMENTOS_BAT 
WHERE 	M47_ST_EXPORTADO = 'S' 
AND 	M47_DT_DIGITACAO <= DATEADD(MONTH,-3,M47_DT_DIGITACAO) 

--Conexão Av.Brasil
--Busca na Av.Brasil os documentos a serem exportados para Lobo Jr.
SELECT M47.M47_NR_SEQUENCIAL,M03_NR_NATUREZA,M47_NR_DOCUMENTO,M30_CD_EMPRESA,
M47_DT_DIGITACAO,M47_DT_DOCUMENTO,M27_CD_USUARIO,M47_TX_OBSERVACAO,
M47_ST_VALOR,M47_VL_TOTAL_DOC,M47_ST_SITUACAO,M47_IN_REPROCESSO,
M47_NR_NF_FORNECEDOR,M47_ST_EXPORTADO,M47_CD_SISTEMA_ORIGEM, 
M48_NR_POSICAO,L03_NR_DV,L03_CD_MATERIAL,M06_SG_UNIDADE,M48_NR_QUANTIDADE,
M11_CD_CCUSTO_ATENDE,M11_NR_CONTA_ATENDE,M11_CD_CCUSTO_RECEBE,
M11_NR_CONTA_RECEBE,M48_VL_UNITARIO_1,M48_VL_UNITARIO_2 
FROM sybase..MAT_M47_DOCUMENTOS_BAT M47, 
sybase..MAT_M48_DOC_MATERIAIS_BAT M48 
WHERE M47.M47_NR_SEQUENCIAL = M48.M47_NR_SEQUENCIAL 
AND M47_ST_EXPORTADO = 'N' 
--Não busca os documentos que não devem ser gerados no sistema de materiais
AND NOT EXISTS (SELECT 1 FROM tec_fitas..TNF_T04_PROCESSOS_OFF T04
                INNER JOIN tec_fitas..TNF_T07_DESTINOS_ROMANEIO T07
                ON T07.T04_ID_PROCESSO = T04.T04_ID_PROCESSO
                WHERE M11_CD_CCUSTO_ATENDE = T04.M07_CD_CCUSTO_RECEBE
                AND M11_CD_CCUSTO_RECEBE = T07.M07_CD_CCUSTO_RECEBE
                AND T07_ST_GERA_DOC_MATERIAIS = 'N')
ORDER BY M47_CD_SISTEMA_ORIGEM,M47.M47_NR_SEQUENCIAL 
/*
M47_NR_SEQUENCIAL M03_NR_NATUREZA M47_NR_DOCUMENTO M30_CD_EMPRESA M47_DT_DIGITACAO        M47_DT_DOCUMENTO        M27_CD_USUARIO M47_TX_OBSERVACAO              M47_ST_VALOR M47_VL_TOTAL_DOC                        M47_ST_SITUACAO M47_IN_REPROCESSO M47_NR_NF_FORNECEDOR M47_ST_EXPORTADO M47_CD_SISTEMA_ORIGEM M48_NR_POSICAO L03_NR_DV L03_CD_MATERIAL M06_SG_UNIDADE M48_NR_QUANTIDADE                       M11_CD_CCUSTO_ATENDE M11_NR_CONTA_ATENDE M11_CD_CCUSTO_RECEBE M11_NR_CONTA_RECEBE M48_VL_UNITARIO_1                       M48_VL_UNITARIO_2
----------------- --------------- ---------------- -------------- ----------------------- ----------------------- -------------- ------------------------------ ------------ --------------------------------------- --------------- ----------------- -------------------- ---------------- --------------------- -------------- --------- --------------- -------------- --------------------------------------- -------------------- ------------------- -------------------- ------------------- --------------------------------------- ---------------------------------------
16550689          11              18244            1              2024-06-20 11:51:00     2024-06-20 00:00:00     PROC06         Referente à OFF: 18244         N            0.0000                                  N               S                 NULL                 N                TDF                   1              1         33731000        KG             6.80                                    9022                 142.42              9118                 141.41              0.0000                                  0.0000
16550690          11              18244            1              2024-06-20 11:52:00     2024-06-20 00:00:00     PROC06         Referente à OFF: 18244         N            0.0000                                  N               S                 NULL                 N                TDF                   1              1         33731000        KG             6.00                                    9022                 142.42              9118                 141.41              0.0000                                  0.0000
16550692          11              26200            1              2024-06-21 16:12:00     2024-06-21 00:00:00     PROC06         Referente à OFF: 26200         N            0.0000                                  N               S                 NULL                 N                TDF                   1              1         33731000        KG             37.80                                   9022                 142.42              9118                 141.41              0.0000                                  0.0000
16550699          20              16550699         1              2024-07-17 08:28:00     2024-07-17 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         30271400        KG             17.00                                   8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550700          20              16550700         1              2024-07-17 09:59:00     2024-07-17 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         30271400        KG             10.00                                   8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550701          11              11111            1              2024-07-17 10:03:00     2024-07-17 00:00:00     PROC06         Referente à OFF: 11111         N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         30271400        KG             5.00                                    9022                 140.40              9123                 141.41              0.0000                                  0.0000
16550702          12              11111            1              2024-07-17 10:05:00     2024-07-17 00:00:00     PROC06         OFF: 11111 - Rom.: 00553       N            0.0000                                  N               S                 NULL                 N                TDF                   1              4         E327147V        MT             249.40                                  9123                 141.41              9072                 142.42              0.0000                                  0.0000
16550703          11              12345            1              2024-07-18 15:41:00     2024-07-18 00:00:00     PROC06         Referente à OFF: 12345         N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         30271400        KG             4.00                                    9022                 140.40              9123                 141.41              0.0000                                  0.0000
16550704          12              12345            1              2024-07-18 15:51:00     2024-07-18 00:00:00     PROC06         OFF: 12345 - Rom.: 00554       N            0.0000                                  N               S                 NULL                 N                TDF                   1              4         E327147V        MT             133.40                                  9123                 141.41              9072                 142.42              0.0000                                  0.0000
16550705          12              12345            1              2024-07-18 16:26:00     2024-07-18 00:00:00     PROC06         OFF: 12345 - Rom.: 00556       N            0.0000                                  N               S                 NULL                 N                TDF                   1              4         E327147V        MT             133.40                                  9123                 141.41              9072                 142.42              0.0000                                  0.0000
16550706          11              12347            1              2024-07-18 16:28:00     2024-07-18 00:00:00     PROC06         Referente à OFF: 12347         N            0.0000                                  N               S                 NULL                 N                TDF                   1              4         E327147V        MT             133.40                                  9072                 142.42              9118                 141.41              0.0000                                  0.0000
16550710          20              16550710         1              2024-09-05 10:34:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         33738100        KG             100.00                                  8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550711          20              16550711         1              2024-09-05 10:44:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              1         30731900        KG             100.00                                  8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550712          20              16550712         1              2024-09-05 10:53:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              7         33738100        KG             50.00                                   8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550713          20              16550713         1              2024-09-05 10:55:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              1         30731900        KG             100.00                                  8299                 401.18              9022                 142.42              0.0000                                  0.0000
16550714          20              16550714         1              2024-09-05 11:54:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              3         E37310XC        MT             3846.20                                 8299                 401.18              9072                 142.42              0.0000                                  0.0000
16550715          20              16550715         1              2024-09-05 11:55:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              3         E37310XC        MT             7692.40                                 8299                 401.18              9072                 142.42              0.0000                                  0.0000
16550716          20              16550716         1              2024-09-05 11:56:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              3         E37310XC        MT             11538.60                                8299                 401.18              9072                 142.42              0.0000                                  0.0000
16550717          20              16550717         1              2024-09-05 13:59:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              9         337310XC        MT             3731.30                                 8299                 401.18              9072                 142.42              0.0000                                  0.0000
16550718          20              16550718         1              2024-09-05 14:00:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              9         337310XC        MT             7462.60                                 8299                 401.18              9072                 142.42              0.0000                                  0.0000
16550719          20              16550719         1              2024-09-05 14:00:00     2024-09-05 00:00:00     PROC06                                        N            0.0000                                  N               S                 NULL                 N                TDF                   1              9         337310XC        MT             11193.90                                8299                 401.18              9072                 142.42              0.0000                                  0.0000

(21 linhas afetadas)
*/


--Conexão Lobo Jr.
select	nr_seq& = M02_TX_PARAMETRO
from	materiais..MAT_M02_PARAMETROS 
set 	M02_TX_PARAMETRO = '17138121'
where 	M02_NR_PARAMETRO = 30

--Conexão Lobo Jr.
cotacao_dolar@ = 1
SELECT 	M37_VL_MOEDA_1
From 	materiais..MAT_M37_CONVERSAO_MOEDAS
WHERE 	M37_DT_COTACAO = (SELECT MAX(M37_DT_COTACAO)
FROM 	materiais..MAT_M37_CONVERSAO_MOEDAS)
cotacao_dolar@=M37_VL_MOEDA_1

--Conexão Lobo Jr.
update	materiais..MAT_M02_PARAMETROS 
set 	M02_TX_PARAMETRO = '17138121'--(nr_seq+1)
where 	M02_NR_PARAMETRO = 30

--Conexão Lobo Jr.
--Insere o documento com o novo sequencial na Lobo Jr.
INSERT INTO materiais..MAT_M47_DOCUMENTOS_BAT 
(M47_NR_SEQUENCIAL,M03_NR_NATUREZA,M47_NR_DOCUMENTO,M30_CD_EMPRESA,
M47_DT_DIGITACAO,M47_DT_DOCUMENTO,M27_CD_USUARIO,M47_TX_OBSERVACAO,
M47_ST_VALOR,M47_VL_TOTAL_DOC,M47_ST_SITUACAO,M47_IN_REPROCESSO,
M47_NR_NF_FORNECEDOR) 
VALUES (17138120,11,
18244,1,
'09/06/2024','08/01/2024',
'PROC06','Referente à OFF: 18244',
'N',0,
'N','S',
Null)
--Conexão Lobo Jr.
--Insere todos os materiais do mesmo sequencial da M47 que foi incluido na Av.Brasil
--com o novo sequencial da M47 da Lobo Jr.
INSERT INTO materiais..MAT_M48_DOC_MATERIAIS_BAT 
(M47_NR_SEQUENCIAL,M48_NR_POSICAO,L03_CD_MATERIAL,L03_NR_DV,
M06_SG_UNIDADE,M48_NR_QUANTIDADE,M11_CD_CCUSTO_ATENDE,
M11_NR_CONTA_ATENDE,M11_CD_CCUSTO_RECEBE,M11_NR_CONTA_RECEBE,
M48_VL_UNITARIO_1, M48_VL_UNITARIO_2) 
VALUES (17138120,1,
'33731000','1',
'KG',6.8,
'9022','142.42',
'9118','141.41',
0,0)

--Conexão Lobo Jr.
--Insere o próximo documento e assim por diante
INSERT INTO materiais..MAT_M47_DOCUMENTOS_BAT 
(M47.M47_NR_SEQUENCIAL,M03_NR_NATUREZA,M47_NR_DOCUMENTO,M30_CD_EMPRESA,
M47_DT_DIGITACAO,M47_DT_DOCUMENTO,M27_CD_USUARIO,M47_TX_OBSERVACAO,
M47_ST_VALOR,M47_VL_TOTAL_DOC,M47_ST_SITUACAO,M47_IN_REPROCESSO,
M47_NR_NF_FORNECEDOR) 
VALUES (17138121,11,
18244,1,
'09/06/2024','08/01/2024',
'PROC06','Referente à OFF: 18244',
'N',0,
'N','S',
Null)
--Conexão Lobo Jr.
--Insere todos os materiais do mesmo sequencial da M47 que foi incluido na Av.Brasil 
--com o novo sequencial da M47 da Lobo Jr.
INSERT INTO materiais..MAT_M48_DOC_MATERIAIS_BAT 
(M47.M47_NR_SEQUENCIAL,M48_NR_POSICAO,L03_CD_MATERIAL,L03_NR_DV,
M06_SG_UNIDADE,M48_NR_QUANTIDADE,M11_CD_CCUSTO_ATENDE,
M11_NR_CONTA_ATENDE,M11_CD_CCUSTO_RECEBE,M11_NR_CONTA_RECEBE,
M48_VL_UNITARIO_1, M48_VL_UNITARIO_2) 
VALUES (17138121,1,
'33731000','1',
'KG',6,
'9022','142.42',
'9118','141.41',
0,0)


--Conexão Av.Brasil
--Atualiza os documentos para exportados na Av.Brasil
UPDATE	sybase..MAT_M47_DOCUMENTOS_BAT 
SET 	M47_ST_EXPORTADO = 'S' 
FROM 	sybase..MAT_M47_DOCUMENTOS_BAT M47
INNER JOIN sybase..MAT_M48_DOC_MATERIAIS_BAT M48 
ON 		M47.M47_NR_SEQUENCIAL = M48.M47_NR_SEQUENCIAL
WHERE 	M47_ST_EXPORTADO = 'N' 
--Só atualizo os documentos gerados no sistema de Materiais
AND NOT EXISTS (SELECT 1 FROM tec_fitas..TNF_T04_PROCESSOS_OFF T04
                INNER JOIN tec_fitas..TNF_T07_DESTINOS_ROMANEIO T07
                ON T07.T04_ID_PROCESSO = T04.T04_ID_PROCESSO
                WHERE M11_CD_CCUSTO_ATENDE = T04.M07_CD_CCUSTO_RECEBE
                AND M11_CD_CCUSTO_RECEBE = T07.M07_CD_CCUSTO_RECEBE
                AND T07_ST_GERA_DOC_MATERIAIS = 'N')


--Conexão Lobo Jr.
--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--Conexão Lobo Jr.
--Libera Bloqueio entidade na Lobo Jr.
/*
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/

--Conexão Av.Brasil
--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--Conexão Av.Brasil
--Libera Bloqueio entidade na Av.Brasil
/*
sistema: 		GDC
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/






Public Function Calcula_DV(ByVal mskCdMaterial As String) As Integer
    
 
    'Função     : Calcula o dígito verificador do material
    'Parâmetros : mskCdMaterial$ - código do material
    'Retorno    : Calcula_DV% - dígito calculado
 
    If Len(Trim(mskCdMaterial)) = 7 Then
        mskCdMaterial = "0" & mskCdMaterial
    End If
 
    Static peso1(1 To 8)
    Static peso2(1 To 9)
    Dim i%, valor_aux%, str_codigo$, DV1%, dig_ver%
 
    peso1(1) = 4
    peso1(2) = 3
    peso1(3) = 8
    peso1(4) = 7
    peso1(5) = 6
    peso1(6) = 5
    peso1(7) = 4
    peso1(8) = 3
    
    peso2(1) = 5
    peso2(2) = 4
    peso2(3) = 3
    peso2(4) = 8
    peso2(5) = 7
    peso2(6) = 6
    peso2(7) = 5
    peso2(8) = 4
    peso2(9) = 3
 
    For i% = 1 To 8
        str_codigo$ = Mid$(mskCdMaterial, i%, 1)
        If str_codigo$ >= "0" And str_codigo$ <= "9" Then
            valor_aux% = Val(str_codigo$)
        ElseIf str_codigo$ >= "A" And str_codigo$ <= "I" Then
            valor_aux% = Asc(str_codigo$) - Asc("A") + 1
        ElseIf str_codigo$ >= "J" And str_codigo$ <= "R" Then
            valor_aux% = Asc(str_codigo$) - Asc("J") + 1
        ElseIf str_codigo$ >= "S" And str_codigo$ <= "Z" Then
            valor_aux% = Asc(str_codigo$) - Asc("S") + 2
        End If
        dig_ver% = dig_ver% + valor_aux% * peso1(i%)
    Next i%
 
    dig_ver% = dig_ver% Mod 10
    DV1% = dig_ver%
 
    dig_ver% = 0
    For i% = 1 To 8
        str_codigo$ = Mid$(mskCdMaterial, i%, 1)
        If str_codigo$ >= "0" And str_codigo$ <= "9" Then
            valor_aux% = Val(str_codigo$)
        ElseIf str_codigo$ >= "A" And str_codigo$ <= "I" Then
            valor_aux% = Asc(str_codigo$) - Asc("A") + 1
        ElseIf str_codigo$ >= "J" And str_codigo$ <= "R" Then
            valor_aux% = Asc(str_codigo$) - Asc("J") + 1
        ElseIf str_codigo$ >= "S" And str_codigo$ <= "Z" Then
            valor_aux% = Asc(str_codigo$) - Asc("S") + 2
        End If
        dig_ver% = dig_ver% + valor_aux% * peso2(i%)
    Next i%
    dig_ver% = dig_ver% + (DV1% * peso2(9))
 
    Calcula_DV% = dig_ver% Mod 10
 
End Function
