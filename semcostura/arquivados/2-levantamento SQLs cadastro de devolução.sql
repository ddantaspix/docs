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

ok - tipoMaterialMovimentoLer
--usar a SP apn..IDM_SP_TIPO_MOVIMENTA_MATERIAL_LER
select	A09_TP_DOCUMENTO, A09_IN_MOVIMENTA_MATERIAIS
from 	APN_A09_MOVIMENTOS
where 	A09_ID_MOVIMENTO = 5--constante movimento tipo DEVOLUCAO
--mensagem retorno se não achou o registro: "Movimentação não encontrada." 
--aborta o processo
--se achar
tpDocumento = A09_TP_DOCUMENTO
inMovimentaMateriais = A09_IN_MOVIMENTA_MATERIAIS

ok - almoxarifadoProcessoLer
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

ok - lerParametroMaterial
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
now < mesAberto
--mensagem retorno: Data do documento inválida

ok - 
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


ok almoxarifadoProcessoLer
--usar a SP apn..IDM_SP_ALMOXARIFADO_PROCESSO_LER
select	1
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 3--idAlmoxarifado
--se não achou o registro: guarda na lista de retorno o idEstoque, idMovimentacao = 0, stRetorno = 0, txRetorno = "Almoxarifado destino não encontrado"

ok - almoxarifadoLocalBuscar
--usar a SP apn..IDM_SP_ALMOXARIFADO_LOCAL_BUSCAR (esta no arquivo scripts das novas SPs para WS de devolução.sql)
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
--usar a SP sybase..IDM_SP_VALIDA_CONTABIL
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

--usar a SP apn..IDM_SP_ALMOXARIFADO_PROCESSO_LER
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
--usar a SP sybase..IDM_SP_VALIDA_CONTABIL
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

tpdocumento, 
cdMaterial
Movimento inválido: Natureza = {0}	Material = {1}, Centro Custo Atende = {2} Conta Atende = {3}, Centro de Custo Recebe = {4}, Conta Recebe = {5}
					
					
--**Fim da validação das informações contábeis

--***********************************************
--***Fim da validação da caixa (idEstoque) ***
--***********************************************



--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO

--usar a SP apn..IDM_SP_CAIXA_DEVOLUCAO_INCLUIR (esta no arquivo scripts das novas SPs para WS de devolução.sql)
--parâmetros a serem passados para SP
/*
idEstoque
cdProcesso
idAlmoxarifado
idLocal
nrPesoLiquidoRequisitado
nrPesoLiquidoDevolvido
nrTara
nrQtdeRequisitada
nrQtdeDevolvida
stParcial
cdUsuario
*/




--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--guarda na lista de retorno o idEstoque, idMovimentacao = <numeroMovimentacao>, stRetorno = 1, txRetorno = "Requisição realizada"

/*
retorno lista<estoque> 
						idEstoque 		int
						idMovimentacao 	int
						stRetorno		int
						txRetorno		varchar(500)
*/