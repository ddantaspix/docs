/*
********************************************************************************************************************************
												Geração de Documentos
********************************************************************************************************************************
*/
--nome rotina WS: documentoGerar
/*
	parâmetros: 
				material		char(08)
				unidade			char(02)
				quantidade		smallmoney
				natureza		int
				ccAtende		char(05)
				contaAtende		char(06)				
				ccRecebe		char(05)
				contaRecebe		char(06)
				cdUsuario		char(08)
*/

--Bloqueio entidades documento
/*
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/

declare @mesAberto 					char(06)
declare	@sequencial					int
declare	@empresa					tinyint


select	@mesAberto = M02_TX_PARAMETRO
from	materiais..MAT_M02_PARAMETROS 
where	M02_NR_PARAMETRO = 23


--Número do próximo documento a ser gerado
select	@sequencial = M02_TX_PARAMETRO
from	materiais..MAT_M02_PARAMETROS
where	M02_NR_PARAMETRO = 30

--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO
--busca a empresa do centro de custo e conta atende (almoxatrifado origem)
select	distinct @empresa = M30_CD_EMPRESA
from	materiais..MAT_M29_SALDOS M29
inner join materiais..MAT_M07_CENTROS_CUSTO M07
on		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
where	M29.M07_CD_CCUSTO = @centroCustoAtende
and		M29.M09_NR_CONTA  = @contaAtende
and 	M07.M07_TP_CCUSTO = 'C'
union
--busca a empresa do centro de custo e conta recebe (almoxatrifado destino)
select	distinct @empresa = M30_CD_EMPRESA
from	materiais..MAT_M29_SALDOS M29
inner join materiais..MAT_M07_CENTROS_CUSTO M07
on		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
where	M29.M07_CD_CCUSTO = @centroCustoRecebe
and		M29.M09_NR_CONTA  = @contaRecebe
and 	M07.M07_TP_CCUSTO = 'C'

	
insert materiais..MAT_M48_DOC_MATERIAIS_BAT 
(
	M47_NR_SEQUENCIAL,
	M48_NR_POSICAO,
	L03_CD_MATERIAL,
	L03_NR_DV,
	M06_SG_UNIDADE,
	M48_NR_QUANTIDADE,
	M11_CD_CCUSTO_ATENDE,
	M11_NR_CONTA_ATENDE,
	M11_CD_CCUSTO_RECEBE,
	M11_NR_CONTA_RECEBE,
	M48_VL_UNITARIO_1,
	M48_VL_UNITARIO_2
)
values 
(
	@sequencial
	1,--sequencial do registro dentro do @sequencial
	@material,
	'9',--ver função no VB (no sistema PROFA, tela de recolhimento)
	@unidade,
	@quantidade,
	@contaAtende,
	@cCustoAtende,
	@contaRecebe,
	@cCustoRecebe,
	0,
	0
)

insert materiais..MAT_M47_DOCUMENTOS_BAT 
(
	M47_NR_SEQUENCIAL,
	M03_NR_NATUREZA,
	M47_NR_DOCUMENTO, 
	M30_CD_EMPRESA,
	M47_DT_DIGITACAO,
	M47_DT_DOCUMENTO,
	M27_CD_USUARIO,
	M47_TX_OBSERVACAO,
	M47_ST_VALOR, 
	M47_VL_TOTAL_DOC,
	M47_ST_SITUACAO,
	M47_IN_REPROCESSO,
	M47_NR_NF_FORNECEDOR
)
values
(
	@sequencial,
	@natureza
	@sequencial,
	@empresa
	convert(date, getdate()),
	convert(date, getdate()),
	@cdUsuario,
	'',
	'N',
	0,
	'N',
	'S',
	null
)


--atualiza o parâmetro com o próximo número de documento
update	materiais..MAT_M02_PARAMETROS
set		M02_tx_parametro = @sequencial + 1--próximo documento a ser gerado
where	M02_NR_Parametro = 30


--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--Libera Bloqueio entidade
/*
sistema: 		MAT
entidade:		NUM_SEQ
modo bloqueio:	R
chave: 			30
*/

