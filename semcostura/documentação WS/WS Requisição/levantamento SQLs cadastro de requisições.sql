/*
********************************************************************************************************************************
												Buscar caixas disponíveis
********************************************************************************************************************************
*/
--caixaBuscarLista
/*
	parâmetros: 
				cdProcesso		int
				lista<material>	char(08)
				idUsuario		int				
*/

/*
Retorno da lista de caixas
*/

/*
--Fátima pediu para tirar - 21/08/2024
--valida permissão usuário x movimento
select	A10_ID_ACESSO --int
from	APN_A10_ACESSOS_USU_MOV 
where	A09_ID_MOVIMENTO = 6 --cdMovimento (requisição)
and		S02_ID_USUARIO = 612 --idUsuario
and		A10_ID_ALMOX_PROC_ORIGEM = 3 --cdAlmoxarifado (fio comprado)
and		A10_ID_ALMOX_PROC_DESTINO = 5 --cdProcesso (tecelagem meias DeMillus)
--mensagem retorno se não achou o registro: O usuário não tem permissão para realizar essa movimentação
--aborta o processo
*/

--para cada material da lista buscar as caixas e guardar na lista de retorno
select	A15.A15_ID_ESTOQUE,
		A15.A02_ID_ALMOX_PROCES,
		A14.L03_CD_MATERIAL, 
		VW13.L03_TX_DESCRICAO,
		A14.A14_ID_ROMANEIO, 
		A14.A14_NR_ROMANEIO, 
		A14.A14_DT_ENTRADA,
		A04.A04_ID_LOCAL,
		A04.A04_CD_LOCAL,
		A04.A04_TX_DESCRICAO,		
		A15.A15_NR_CAIXA, 
		A15.A15_NR_PESO_BRUTO,
		A15.A15_NR_PESO_LIQUIDO,
		A15.A15_NR_TARA,		
		A15.A15_NR_QTDE, 
		A15.A15_NR_NUM_PECA,
		A12.A12_ID_EMBALAGEM, 
		A12.A12_TX_DESCRICAO,
		A14.A14_NR_LOTE, 
		A14.A14_TX_OBSERVACOES		 
from	APN_A14_ROMANEIOS A14
inner join APN_A15_ESTOQUES A15
on		A14.A14_ID_ROMANEIO = A15.A14_ID_ROMANEIO 
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL 
inner join APN_A13_MATERIAIS_PROCES_VIEW VW13
on		A14.L03_CD_MATERIAL = VW13.L03_CD_MATERIAL 
and		A15.A02_ID_ALMOX_PROCES = VW13.A02_ID_ALMOX_PROCES 
inner join APN_A12_EMBALAGENS A12
on		A14.A12_ID_EMBALAGEM = A12.A12_ID_EMBALAGEM
where	A15.A02_ID_ALMOX_PROCES in (3, 19)
/* 
3	FIO COMPRADO
19	FIO BENEFICIADO EXTERNO
*/
and		A14.L03_CD_MATERIAL = '30628725'--cdMaterial da lista<material>
and		A15.A19_ST_PECA = 'D'--constante caixa disponível
order by A14_NR_ROMANEIO,A15_NR_CAIXA,A04_CD_LOCAL
--retorno:  lista de caixas
/*
idEstoque		int
idAmoxarifado	int
cdMaterial		char(08)
txMaterial		char(40)
idRomaneio		int
nrRomaneio		int
dtEntrada		smalldatetime
idLocal			int
cdLocal			char(04)
txLocal			varchar(40)
nrCaixa			smallint
nrPesoBruto		smallmoney
nrPesoLiquido	smallmoney
nrTara			smallmoney
nrQtde			int
nrNumPeca		char(08)
idEmbalagem		int
txEmbalagem		varchar(50)
nrLote			char(07)
observacoes		varchar(255)
*/

/*
********************************************************************************************************************************
												Incluir requisição caixas
********************************************************************************************************************************
*/
--requisicaoIncluir
/*
	parâmetros: 
				cdProcesso			int				
				cdUsuario			char(08)				 							
				lista<estoque>		idEstoque	int
*/

--**********************************
--***Início das validações gerais***
--**********************************
select	A02.A04_ID_LOCAL, A04.A04_TX_DESCRICAO 
from	APN_A02_ALMOX_PROCES A02  
inner join APN_A04_LOCAIS A04
on		A02.A04_ID_LOCAL = A04.A04_ID_LOCAL
and		A02.A02_ID_ALMOX_PROCES = 5--cdProcesso (Tecelagem Meias DeMillus)
--mensagem retorno se não achou registro: "Não foi possível buscar o local do almoxarifado/processo" 
--aborta o processo

select	A09_TP_DOCUMENTO, A09_IN_MOVIMENTA_MATERIAIS
from 	APN_A09_MOVIMENTOS
where 	A09_ID_MOVIMENTO = 6 --constante movimento tipo REQUISIÇÃO
--mensagem retorno se não achou o registro: "Movimentação não encontrada." 
--aborta o processo
--se achar
tpDocumento = A09_TP_DOCUMENTO
inMovimentaMateriais = A09_IN_MOVIMENTA_MATERIAIS

select	M07_CD_CCUSTO, M06_NR_CONTA, A02_IN_PROCESSO
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 5--cdProcesso
--mensagem retorno se não achou o registro: "Não foi possível validar o documento. Centro de custo e conta corrente recebe não encontrados"
--aborta o processo
--se achou
ccRecebe = M07_CD_CCUSTO
inProcessoRecebe = A02_IN_PROCESSO
contaRecebe = M06_NR_CONTA

select	M02_TX_PARAMETRO
from	Sybase..MAT_M02_PARAMETROS M02
where	M02_NR_PARAMETRO = 23--criar constante mês aberto para movimentação
--mensagem retorno se não achou o registro: "Parâmetro de mês aberto para movimentação não encontrado."
--aborta o processo
--se achou
dt_movimento = Trim(ds("M02_TX_PARAMETRO")) & "01"
dt_documento = Format(Now, "YYYYMMDD")

se dt_documento<dt_movimento
--mensagem retorno: Data do documento inválida

select	1
from 	Sybase..MAT_M03_NATUREZAS
where 	M03_NR_NATUREZA = 11--tpDocumento
--mensagem retorno se não achou o registro: Natureza <tpDocumento> não encontrada

--*******************************
--***Fim das validações gerais***
--*******************************


--Bloqueio entidade
/*
sistema: APN
entidade: ESTOQUE
modo bloqueio: R
chave: 2
*/

--***********************************************
--***Início da validação da caixa (idEstoque) ***
--***********************************************

select	A02_ID_ALMOX_PROCES
from	APN_A15_ESTOQUES
where	A15_ID_ESTOQUE = 1047182
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Almoxarifado não encontrado"
--se achou
cdAlmoxarifado = A02_ID_ALMOX_PROCES


select	M07_CD_CCUSTO, M06_NR_CONTA, A02_IN_PROCESSO
from 	APN_A02_ALMOX_PROCES
where 	A02_ID_ALMOX_PROCES = 3 --cdAlmoxarifado
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Não foi possível validar o documento. Centro de custo e conta corrente atende não encontrados"
--se achou
ccAtende = M07_CD_CCUSTO
inProcessoAtende = A02_IN_PROCESSO
contaAtende = M06_NR_CONTA


--Verifica se a caixa ainda esta disponível
select	A15_ID_ESTOQUE
from	APN_A14_ROMANEIOS A14
inner join APN_A15_ESTOQUES A15
on		A14.A14_ID_ROMANEIO = A15.A14_ID_ROMANEIO 	
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL
inner join APN_A13_MATERIAIS_PROCES_VIEW VW13 
on		A14.L03_CD_MATERIAL = VW13.L03_CD_MATERIAL 
and		A15.A02_ID_ALMOX_PROCES = VW13.A02_ID_ALMOX_PROCES 
where	A15.A02_ID_ALMOX_PROCES = 3 --cdAlmoxarifado (fio comprado)
and		A15.A19_ST_PECA = 'A'--constante caixa aguardando confirmação
and		A15.A15_ID_ESTOQUE = 1047182--idEstoque
--se achou a caixa atualiza na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Caixa não esta mais disponível"

--Verifica se tem NR não confirmada para caixa
select	count(isnull(A18_ID_MOVIMENTACAO,0))
from	APN_A18_MOVIMENTACOES
where	(A18_ST_LIBERADO_MATERIAIS = 'N' or A18_ST_LIBERADO_MATERIAIS is null)
and		A09_ID_MOVIMENTO in (1,3,5,6,9,10)--criar constantes
and		A15_ID_ESTOQUE = 1047182
--se achou a caixa guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Existe movimentação em aberto para o material/caixa."

/*
select	A09_ID_MOVIMENTO, A09_TX_DESCRICAO
from	APN_A09_MOVIMENTOS
where	A09_ID_MOVIMENTO in (1,3,5,6,9,10)
A09_ID_MOVIMENTO A09_TX_DESCRICAO
---------------- ----------------------------------------
1                BAIXA DE ESTOQUE
3                TRANSFERÊNCIA
5                DEVOLUÇÃO AO ESTOQUE
6                REQUISIÇÃO
9                REQUISIÇÃO AUTOMÁTICA
10               RETORNO AO PROCESSO
*/

--**Início da validação das informações contábeis
se inMovimentaMateriais = N -> não precisa validar informações contábeis do material porque o tipo movimento REQUISIÇÃO não controla a movimentação do estoque

se inProcessoAtende = N
					select	M29.M09_NR_CONTA
					from 	APN_A02_ALMOX_PROCES A02
					inner join Sybase..MAT_M29_SALDOS M29
					on		A02.M07_CD_CCUSTO = M29.M07_CD_CCUSTO
					where	A02.A02_ID_ALMOX_PROCES = 3--cdAlmoxarifado
					and 	M29.L03_CD_MATERIAL = '30090213'--cdMaterial
					and 	A02.A02_IN_PROCESSO = 'N'
					and 	M29.M30_CD_EMPRESA in ('01','21')--Empresas existentes no Apn: 01-DeMillus, 21-Secret
					--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Não foi possível validar o documento. Conta corrente atende estoque não encontrada"
					--se achou
					contaAtende = M09_NR_CONTA
					
se inProcessoRecebe = N
						select 	M29.M09_NR_CONTA
						from	APN_A02_ALMOX_PROCES A02
						inner join Sybase..MAT_M29_SALDOS M29
						on		A02.M07_CD_CCUSTO = M29.M07_CD_CCUSTO
						where 	A02.A02_ID_ALMOX_PROCES = 5 --cdProcesso
						and 	M29.L03_CD_MATERIAL = '30090213'--cdMaterial
						and 	A02.A02_IN_PROCESSO = 'N'
						and 	M29.M30_CD_EMPRESA in ('01','21')--Empresas existentes no Apn: 01-DeMillus, 21-Secret
						--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Não foi possível validar o documento. Conta corrente recebe estoque não encontrada"
						--se achou
						contaRecebe = M09_NR_CONTA

select	1
from 	Sybase..MAT_M11_MOVIMENTOS
where 	M03_NR_NATUREZA = 11--tpDocumento
and 	M11_NR_CONTA_ATENDE = '140.40'--contaAtende
and 	M11_CD_CCUSTO_ATENDE = '9030'--ccAtende
and 	M11_NR_CONTA_RECEBE = '141.41'--contaRecebe
and 	M11_CD_CCUSTO_RECEBE = '9102'--ccRecebe
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = mensagem retorno abaixo
/*
mensagem retorno: 
					Movimento inválido.
					Natureza = <tpDocumento>
					Material = <cdMaterial>
					Centro Custo Atende = <ccAtende>
					Conta Atende = <contaAtende>
					Centro de Custo Recebe = <ccRecebe>
					Conta Recebe = <contaRecebe>
*/        
--**Fim da validação das informações contábeis        

--***********************************************
--***Fim da validação da caixa (idEstoque) ***
--***********************************************


--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO
insert APN_A18_MOVIMENTACOES 
(A09_ID_MOVIMENTO, A15_ID_ESTOQUE, A18_ID_ALMOX_ORIGEM, A18_ID_ALMOX_DESTINO, A11_ID_MOTIVO, A18_DT_MOVIMENTO,
A18_NR_PESO_LIQUIDO, A18_NR_QTDE_EMBALAGEM, A18_ST_EXPORTA_MATERIAIS, PP_TX_USER_STAMP, A18_ST_LIBERADO_MATERIAIS) 
select	6, 1034710, 3, 5, null, convert(varchar(20),getdate(),101),
		A15_NR_PESO_LIQUIDO, A15_NR_QTDE, 'N', 'PIX13', 'N'
/*
select	<contante_tp_movimento_requisicao>, idEstoque, cdAlmoxarifado, cdProcesso, null, convert(varchar(20),getdate(),101),
		A15_NR_PESO_LIQUIDO, A15_NR_QTDE, 'N', cdUsuario, 'N'
*/		
from	APN_A15_ESTOQUES		
where	A15_ID_ESTOQUE = 1034710--idEstoque		
		
update	APN_A15_ESTOQUES
set		A02_ID_ALMOX_PROCES = 5,--cdProcesso
		A19_ST_PECA = 'A',--constante caixa aguardando confirmação
		PP_TX_USER_STAMP = 'PIX13'--cdUsuario
where	A15_ID_ESTOQUE = 1034710--idEstoque
--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--guarda na lista de retorno o idEstoque, idMovimentacao = <numeroMovimentacao>, stRetorno = 1, txRetorno = "Requisição realizada"

--Desbloqueio entidade
/*
sistema: APN
entidade: ESTOQUE
modo bloqueio: R
chave: 2
*/

/*
retorno lista<estoque> 
						idEstoque 		int
						idMovimentacao 	int
						stRetorno		int
						txRetorno		varchar(500)
*/