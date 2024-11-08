
USE [sybase]
GO

/****** Object:  StoredProcedure [dbo].[IDM_SP_PARAMETRO_MATERIAL_LER]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_PARAMETRO_MATERIAL_LER]
(
	@nrParametro int
)
AS
BEGIN
	
select	M02_TX_PARAMETRO AS TX_PARAMETRO
from	MAT_M02_PARAMETROS M02
where	M02_NR_PARAMETRO = @nrParametro

END

GO

/****** Object:  StoredProcedure [dbo].[IDM_SP_NATUREZA_EXISTE]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_NATUREZA_EXISTE]
(
	@nrNatureza int
)
AS
BEGIN
	
select	1
from 	MAT_M03_NATUREZAS
where 	M03_NR_NATUREZA = @nrNatureza

END

GO

/****** Object:  StoredProcedure [dbo].[IDM_SP_VALIDA_CONTABIL]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_VALIDA_CONTABIL]
(
	@idAlmoxarifado int,
	@cdMaterial char(08)
)
AS
BEGIN

select	M29.M09_NR_CONTA AS NR_CONTA
					from 	APN_A02_ALMOX_PROCES A02
					inner join MAT_M29_SALDOS M29
					on		A02.M07_CD_CCUSTO = M29.M07_CD_CCUSTO
					where	A02.A02_ID_ALMOX_PROCES = @idAlmoxarifado--cdAlmoxarifado
					and 	M29.L03_CD_MATERIAL = @cdMaterial--cdMaterial
					and 	A02.A02_IN_PROCESSO = 'N'
					and 	M29.M30_CD_EMPRESA in ('01','21')
					
END


GO


/****** Object:  StoredProcedure [dbo].[IDM_SP_VALIDA_CONTABIL]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_EXISTE_MOVIMENTO]
(
	@tpDocumento int,
	@contaAtende char(6),
	@ccAtende char(6),
	@contaRecebe char(6),
	@ccRecebe char(6)
	
)
AS
BEGIN

select	1
from 	MAT_M11_MOVIMENTOS
where	M03_NR_NATUREZA = @tpDocumento
and 	M11_NR_CONTA_ATENDE = @contaAtende
and 	M11_CD_CCUSTO_ATENDE = @ccAtende
and 	M11_NR_CONTA_RECEBE = @contaRecebe  
and 	M11_CD_CCUSTO_RECEBE = @ccRecebe 

END



GO