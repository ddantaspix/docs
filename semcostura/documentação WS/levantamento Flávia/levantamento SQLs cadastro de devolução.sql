/*
********************************************************************************************************************************
											Enviar caixas para devolução ao estoque
********************************************************************************************************************************
*/
/*
	parâmetros: 
				cdProcesso		int				
				lista<estqoue>	
								idEstoque					int
								idAlmoxarifado				int
								idLocal						int
								nrPesoLiquidoRequisitado	smallmoney
								nrPesoLiquidoDevolvido		smallmoney
								nrTara						smallmoney
								nrQtdeRequisitada			int
								nrQtdeDevolvida				int
								stParcial					int
				idUsuario		int
				cdUsuario		char(08)
*/

/*
retorno lista<estoque> 
						idEstoque 		int
						idMovimentacao 	int
						stRetorno		int
						txRetorno		varchar(500)
*/

--**********************************
--***Início das validações gerais***
--**********************************
--usar a SP apn..IDM_SP_TIPO_MOVIMENTA_MATERIAL_LER
select	A09_TP_DOCUMENTO, A09_IN_MOVIMENTA_MATERIAIS
from 	APN_A09_MOVIMENTOS
where 	A09_ID_MOVIMENTO = 5--constante movimento tipo DEVOLUCAO
--mensagem retorno se não achou o registro: "Movimentação não encontrada." 
--aborta o processo
--se achar
tpDocumento = A09_TP_DOCUMENTO
inMovimentaMateriais = A09_IN_MOVIMENTA_MATERIAIS


--usar a SP apn..IDM_SP_ALMOXARIFADO_PROCESSO_LER
select	M07_CD_CCUSTO, M06_NR_CONTA, A02_IN_PROCESSO
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 5--cdProcesso
--mensagem retorno se não achou o registro: "Não foi possível validar o documento. Centro de custo e conta corrente atende não encontrados"
--aborta o processo
--se achou
ccAtende = M07_CD_CCUSTO
inProcessoAtende = A02_IN_PROCESSO
contaAtende = M06_NR_CONTA


--usar a SP sybase..IDM_SP_PARAMETRO_MATERIAL_LER
select	M02_TX_PARAMETRO
from	Sybase..MAT_M02_PARAMETROS
where	M02_NR_PARAMETRO = 23--criar constante mês aberto para movimentação
--mensagem retorno se não achou o registro: "Parâmetro de mês aberto para movimentação não encontrado."
--aborta o processo
--se achou
dt_movimento = Trim(ds("M02_TX_PARAMETRO")) & "01"
dt_documento = Format(Now, "YYYYMMDD")

se dt_documento<dt_movimento
--mensagem retorno: Data do documento inválida


--usar a SP sybase..IDM_SP_NATUREZA_EXISTE
select	1
from 	Sybase..MAT_M03_NATUREZAS
where 	M03_NR_NATUREZA = 13--tpDocumento
--mensagem retorno se não achou o registro: Natureza <tpDocumento> não encontrada

--*******************************
--***Fim das validações gerais***
--*******************************



--***********************************************
--***Início da validação da caixa (idEstoque) ***
--***********************************************

--usar a SP apn..IDM_SP_ALMOXARIFADO_PROCESSO_LER
select	1
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 3--idAlmoxarifado
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Almoxarifado destino não encontrado"

--usar a SP apn..IDM_SP_ALMOXARIFADO_LOCAL_BUSCAR
select	1
from	APN_A04_LOCAIS
where	A02_ID_ALMOX_PROCES = 3--idAlmoxarifado
and		A04_CD_LOCAL = 'H6-1'--cdLocal
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Local no almoxarifado destino não encontrado"

--validar preenchimento obrigatório e maior que zero: nrPesoLiquidoDevolvido, nrTara, nrQtdeDevolvida
--se cair em crítica
--nrPesoLiquidoDevolvido:guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Peso líquido não informado"
--nrTara:guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Tara não informada"
--nrQtdeDevolvida:guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Quantidade de embalagem ão informada"


--se stParcial = 1
--se nrPesoLiquidoDevolvido>=nrPesoLiquidoRequisitado
--guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "O peso a ser devolvido deve ser MENOR do que o peso original da caixa (<nrPesoLiquidoRequisitado>). Favor selecionar Devolução Total ou alterar o valor a ser devolvido."
                

--se cdProcesso = idAlmoxarifado
--guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Origem e Destino devem ser diferentes para movimentos diferentes de Baixa"

--**Início da validação das informações contábeis
se inMovimentaMateriais = N -> não precisa validar informações contábeis do material porque o tipo movimento REQUISIÇÃO não controla a movimentação do estoque

inProcessoAtende = N
--usar a mesma SP utilizada no cadastro da requisição
				select	M29.M09_NR_CONTA
				from	APN_A02_ALMOX_PROCES A02
				inner join sybase..MAT_M29_SALDOS M29
				on		A02.M07_CD_CCUSTO = M29.M07_CD_CCUSTO
				where	A02.A02_ID_ALMOX_PROCES = 5--cdProcesso
				and		M29.L03_CD_MATERIAL = '30628725'--cdMaterial
				and		A02.A02_IN_PROCESSO = 'N'
				and		M29.M30_CD_EMPRESA in ('01','21')--Empresas existentes no Apn: 01-DeMillus, 21-Secret
				--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Não foi possível validar o documento. Conta corrente atende estoque não encontrada"
				--se achou
				contaAtende = M09_NR_CONTA				


select	M07_CD_CCUSTO, M06_NR_CONTA, A02_IN_PROCESSO
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 3--idAlmoxarifado
--mensagem retorno se não achou o registro: "Não foi possível validar o documento. Centro de custo e conta corrente recebe não encontrados"
--aborta o processo
--se achou
ccRecebe = M07_CD_CCUSTO
inProcessoRecebe = A02_IN_PROCESSO
contaRecebe = M06_NR_CONTA

inProcessoRecebe = N
--usar a mesma SP utilizada no cadastro da requisição
				select	M29.M09_NR_CONTA
				from	APN_A02_ALMOX_PROCES A02
				inner join sybase..MAT_M29_SALDOS M29
				on		A02.M07_CD_CCUSTO = M29.M07_CD_CCUSTO
				where 	A02.A02_ID_ALMOX_PROCES = 3--idAlmoxarifado
				and		M29.L03_CD_MATERIAL = '30628725'--cdMaterial
				and		A02.A02_IN_PROCESSO = 'N'
				and		M29.M30_CD_EMPRESA in ('01','21')--Empresas existentes no Apn: 01-DeMillus, 21-Secret
				--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Não foi possível validar o documento. Conta corrente recebe estoque não encontrada"
				--se achou
				contaRecebe = M09_NR_CONTA		


--usar a mesma SP utilizada no cadastro da requisição				
select	1
from 	sybase..MAT_M11_MOVIMENTOS
where	M03_NR_NATUREZA = 13--tpDocumento
and 	M11_NR_CONTA_ATENDE = '141.41'--contaAtende
and 	M11_CD_CCUSTO_ATENDE = '9102'--ccAtende
and 	M11_NR_CONTA_RECEBE = '140.40'--contaRecebe
and 	M11_CD_CCUSTO_RECEBE = '9030'--ccRecebe
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
--cria um novo idEstoque na A15 com
select	max(A15_ID_ESTOQUE)+1 
from 	APN_A15_ESTOQUES
--id_estoque_novo


--insere a movimentação para o novo estoque
insert APN_A18_MOVIMENTACOES
(A09_ID_MOVIMENTO, A15_ID_ESTOQUE, A18_ID_ALMOX_ORIGEM, A18_ID_ALMOX_DESTINO, A11_ID_MOTIVO, A18_DT_MOVIMENTO, 
A18_NR_PESO_LIQUIDO, A18_NR_QTDE_EMBALAGEM, A18_ST_EXPORTA_MATERIAIS, A18_VL_BAIXA, PP_TX_USER_STAMP)
values 
--<contante_tp_movimento_devolucao>, id_estoque_novo, cdProcesso, idAlmoxarifado, null, convert(varchar(20),getdate(),101)
(5, 1054885, 5, 3, Null, convert(varchar(20),getdate(),101),
--nrPesoLiquidoDevolvido, nrQtdeRequisitada, N, null, cdUsuario 
21.93000, 6, 'N', NULL, 'PIX13')

select	PESO_CAIXA = A15_NR_PESO_BRUTO - A15_NR_PESO_LIQUIDO,
		NR_CAIXA = (
						select	max(A15_NR_CAIXA) + 1 
						from	APN_A15_ESTOQUES A15a
						where	A15.A14_ID_ROMANEIO = A15a.A14_ID_ROMANEIO
					) 
from	APN_A15_ESTOQUES A15
where	A15.A15_ID_ESTOQUE = 626290--idEstoque
--se não achou   
--pesoCaixa = 0 e nrCaixa = 1
--se achou pesoCaixa=PESO_CAIXA e nrCaixa=NR_CAIXA

--guarda no log o estqoue antigo
insert  APN_A15_ESTOQUES_LOG 
(A15_ID_ESTOQUE, A14_ID_ROMANEIO, A02_ID_ALMOX_PROCES, A04_ID_LOCAL, A15_NR_CAIXA,A15_NR_PESO_BRUTO, A15_NR_PESO_LIQUIDO,
A15_NR_TARA, A15_NR_QTDE, A19_ST_PECA, A15_NR_NUM_PECA, PP_TM_TIME_STAMP,PP_TX_USER_STAMP, 
A15_ST_IMPRESSO, A15_ST_ALTERADA,A15_NR_NOVA_CAIXA)
select	A15_ID_ESTOQUE, A14_ID_ROMANEIO,A02_ID_ALMOX_PROCES, A04_ID_LOCAL, A15_NR_CAIXA, A15_NR_PESO_BRUTO, A15_NR_PESO_LIQUIDO,
		A15_NR_TARA, A15_NR_QTDE, A19_ST_PECA, A15_NR_NUM_PECA, getdate(), 'PIX13',--cdUsuario
		A15_ST_IMPRESSO, A15_ST_ALTERADA, 57--nrCaixa
from	APN_A15_ESTOQUES
where	A15_ID_ESTOQUE = 626290--idEstoque

--atualiza o estoque antigo com o novo peso da caixa utilizada
update	APN_A15_ESTOQUES
set		A15_NR_PESO_BRUTO = 6.39,--pesoCaixa + (nrPesoLiquidoRequisitado - nrPesoLiquidoDevolvido)
		A15_NR_PESO_LIQUIDO = 4.39,--(nrPesoLiquidoRequisitado - nrPesoLiquidoDevolvido)
		A19_ST_PECA = 'D',--constante caixa disponível
		PP_TX_USER_STAMP = 'PIX13',--cdUsuario
		A15_ST_ALTERADA = 'S'
where	A15_ID_ESTOQUE = 626290--idEstoque

--insere o novo estoque com o peso das caixas devolvidas
insert APN_A15_ESTOQUES 
(A15_ID_ESTOQUE, A14_ID_ROMANEIO, A02_ID_ALMOX_PROCES, A04_ID_LOCAL, A15_NR_CAIXA, A15_NR_PESO_BRUTO, A15_NR_PESO_LIQUIDO,
A15_NR_TARA, A15_NR_QTDE, A19_ST_PECA, A15_NR_NUM_PECA, PP_TM_TIME_STAMP, PP_TX_USER_STAMP, A15_ST_IMPRESSO, A15_ST_ALTERADA)
--select id_estoque_novo, A14_ID_ROMANEIO, idAlmoxarifado, idLocal, nrCaixa, (nrPesoLiquidoDevolvido+nrTara), nrPesoLiquidoDevolvido,
select	1054885, A14_ID_ROMANEIO, 3, 437, 57, 24.11, 21.93000, 
--		nrTara, nrQtdeDevolvida, 'A', A15_NR_NUM_PECA, getdate(), 'PIX13', A15_ST_IMPRESSO ,'N'
		2.18000, 5.000, 'A', A15_NR_NUM_PECA, getdate(), 'PIX13', A15_ST_IMPRESSO ,'N'
from 	APN_A15_ESTOQUES
where 	A15_ID_ESTOQUE = 626290--idEstoque


--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--guarda na lista de retorno o idEstoque, idMovimentacao = <numeroMovimentacao>, stRetorno = 1, txRetorno = "Requisição realizada"

/*
retorno lista<estoque> 
						idEstoque 		int
						idMovimentacao 	int
						stRetorno		int
						txRetorno		varchar(500)
*/