/*
********************************************************************************************************************************
												Confirmação de Pagamento
********************************************************************************************************************************
*/
--requisicoesConfirmarPagamentoBuscarLista
/*
	parâmetros: 
				cdProcesso	int
*/
select	A15.A15_ID_ESTOQUE,
		A14.L03_CD_MATERIAL, 
		M15.L03_TX_DESCRICAO,
		A14.A14_ID_ROMANEIO, 
		A14.A14_NR_ROMANEIO, 
		A14.A14_DT_ENTRADA,
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
from	APN_A15_ESTOQUES A15
inner join APN_A14_ROMANEIOS A14
on		A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
inner join APN_A18_MOVIMENTACOES A18
on		A15.A15_ID_ESTOQUE = A18.A15_ID_ESTOQUE
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL
inner join Sybase..MAT_M15_MATERIAIS M15
on		A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
inner join APN_A12_EMBALAGENS A12
on		A14.A12_ID_EMBALAGEM = A12.A12_ID_EMBALAGEM
where	A18.A18_ID_ALMOX_DESTINO = 5--cdProcesso (tecelagem de meias)
and		A15.A19_ST_PECA = 'A'--constante (aguardando confirmação)
and		(A18.A18_ST_LIBERADO_MATERIAIS is null or A18.A18_ST_LIBERADO_MATERIAIS = 'N')
order by A14.A14_NR_ROMANEIO, A15.A15_NR_CAIXA 
--retorno:  lista de caixas
/*
idEstoque		int
cdMaterial		char(08)
txMaterial		char(40)
idRomaneio		int
nrRomaneio		int
dtEntrada		smalldatetime
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
												Confirmação de Pagamento
********************************************************************************************************************************
*/
----requisicaoConfirmarPagamento
/*
	parâmetros: 
				cdProcesso		int
				cdUsuario		char(08)				 							
				lista<estoque>	idEstoque		int
*/
--verifica bloqueio de inventário
select	DT_HOJE = getdate(),DT_BLOQUEIO = convert (Varchar(10),I47_DT_BLOQUEIO,103), NR_PARAMETRO = I47_NR_PARAMETRO 
from 	sybase..INV_I47_CRONOGRAMA_INVENTARIO_PROCESSO 
where 	I47_NR_PARAMETRO = 7--constante último pagamento fios
union 
select	DT_HOJE = getdate(),DT_BLOQUEIO = I01_TX_PARAMETRO,NR_PARAMETRO = I01_NR_PARAMETRO 
from 	sybase..INV_I01_PARAMETROS 
where 	I01_NR_PARAMETRO  = 48--constante data inventário geral de matéria prima
order by NR_PARAMETRO 
--Dt_Ini_bloqueio = Format(Dys("DT_BLOQUEIO"), "dd/mm/yyyy")--parâmetro 7
--Dt_Fim_bloqueio = Format(Dys("DT_BLOQUEIO"), "dd/mm/yyyy")--parâmetro 48
se CVDate(Format(Dys("DT_HOJE"), "dd/mm/yyyy")) > CVDate(Dt_Ini_bloqueio) 
e  CVDate(Format(Dys("DT_HOJE"), "dd/mm/yyyy")) <= CVDate(Dt_Fim_bloqueio) 
--mensagem retorno: Função bloqueada para o Inventário de Matéria Prima e Processo. Caso seja necessário alterar, entre em contato com o SETOR DE CUSTOS.
--aborta o processo


--Bloqueio entidade
/*
sistema: APN
entidade: ESTOQUE
modo bloqueio: T
chave: vazio
*/

select	A02_IN_CONTROLA_ESTOQUE
from	APN_A02_ALMOX_PROCES
where	A02_ID_ALMOX_PROCES = 5--cdProcesso
--se não achou registro: "Proceso não encontrado"
--aborta o processo

se A02_IN_CONTROLA_ESTOQUE = S -> status = D
se A02_IN_CONTROLA_ESTOQUE = N -> status = F


--INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO INICIO TRANSAÇÃO

--início loop na lista de estoque

select	A02.A04_ID_LOCAL, A04.A04_TX_DESCRICAO 
from	APN_A15_ESTOQUES A15
inner join APN_A02_ALMOX_PROCES A02
on		A15.A02_ID_ALMOX_PROCES = A02.A02_ID_ALMOX_PROCES
inner join APN_A04_LOCAIS A04 
on		A02.A04_ID_LOCAL = A04.A04_ID_LOCAL 
where	A15.A15_ID_ESTOQUE = 1034710--idEstoque
--se não achou o registro: guarda na lista de retorno o idEstoque, txRetorno = "Local do almoxarifado não encontrado", stConfirmado = 0
--se achou
idLocal = A04_ID_LOCAL

update	APN_A15_ESTOQUES
set		A19_ST_PECA = 'D',--status
		A04_ID_LOCAL = 3,--idLocal
		PP_TX_USER_STAMP = 'PIX13'--cdUsuario
where	A15_ID_ESTOQUE = 1034710--idEstoque
and		A19_ST_PECA <> 'F'--peça finalizada (criar constantes)

update	APN_A15_ESTOQUES
set 	A04_ID_LOCAL = 3,--idLocal
		PP_TX_USER_STAMP = 'PIX13'--cdUsuario
where	A15_ID_ESTOQUE = 1034710--idEstoque
and		A19_ST_PECA = 'F'--peça finalizada (criar constante)

update	APN_A18_MOVIMENTACOES 
set		A18_ST_LIBERADO_MATERIAIS = 'S',
		PP_TX_USER_STAMP = 'PIX13'--cdUsuario
where	A15_ID_ESTOQUE = 1034710--idEstoque

--guarda na lista de retorno o idEstoque, txRetorno = "Pagamento Confirmado", stConfirmado = 1

--fim loop na lista de estoque

--FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO FIM TRANSAÇÃO

--Desbloqueio entidade
/*
sistema: APN
entidade: ESTOQUE
modo bloqueio: T
chave: vazio
*/