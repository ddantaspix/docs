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
from	APN_A15_ESTOQUES A15
inner join APN_A14_ROMANEIOS A14
on		A15.A14_ID_ROMANEIO = A14.A14_ID_ROMANEIO
inner join APN_A18_MOVIMENTACOES A18
on		A15.A15_ID_ESTOQUE = A18.A15_ID_ESTOQUE
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL
inner join Sybase..MAT_M15_MATERIAIS M15
on		A14.L03_CD_MATERIAL = M15.L03_CD_MATERIAL
where	A18.A18_ID_ALMOX_DESTINO = 5--cdProcesso (tecelagem de meias)
and		A15.A19_ST_PECA = 'A'--constante (aguardando confirmação)
and		(A18.A18_ST_LIBERADO_MATERIAIS is null or A18.A18_ST_LIBERADO_MATERIAIS = 'N')
order by A02.A02_TX_DESCRICAO, A14.A14_NR_ROMANEIO, A15.A15_NR_CAIXA 
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