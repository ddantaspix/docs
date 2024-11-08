---------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURES
---------------------------------------------------------------------------------------------------------------------------------------------------
/****** Object:  StoredProcedure [dbo].[ISC_SP_PESOS_EMBALAGEM_BUSCAR]    Script Date: 04/10/2024 15:09:39 ******/
------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[ISC_SP_PESOS_EMBALAGEM_BUSCAR]
(
	@cdMaterial char(8)
)
AS

BEGIN

DECLARE @FIO_MANIPULADO AS int = 2
DECLARE @FIO_COMPRADO AS int = 3
DECLARE @FIO_BENEFICIADO_EXTERNO AS int = 19
DECLARE @ST_PECA_FINALIZADA AS char(1) = 'F'
DECLARE @ST_PECA_INDISPONIVEL AS char(1) = 'I'

select	A14.L03_CD_MATERIAL AS CD_MATERIAL,
		A12.A12_TX_DESCRICAO AS TX_EMBALAGEM,
		--sum(A15.A15_NR_PESO_LIQUIDO)/sum(A15.A15_NR_QTDE)--o peso é em kg ou gr	
		PESO_KG=sum(A15.A15_NR_PESO_LIQUIDO)/sum(A15.A15_NR_QTDE),
		PESO_GR=(convert(money,sum(convert(money,A15.A15_NR_PESO_LIQUIDO)))/1000)/sum(A15.A15_NR_QTDE)			
from	APN_A14_ROMANEIOS A14
inner join APN_A15_ESTOQUES A15
on		A14.A14_ID_ROMANEIO = A15.A14_ID_ROMANEIO 
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL 
inner join APN_A12_EMBALAGENS A12
on		A14.A12_ID_EMBALAGEM = A12.A12_ID_EMBALAGEM
where	A15.A02_ID_ALMOX_PROCES in (@FIO_MANIPULADO, @FIO_COMPRADO, @FIO_BENEFICIADO_EXTERNO)--2-FIO MANIPULADO/3-FIO COMPRADO/19-FIO BENEFICIADO EXTERNO
and		A15.A19_ST_PECA not in (@ST_PECA_FINALIZADA, @ST_PECA_INDISPONIVEL)--FINALIZADA/INDISPONÍVEL
and (@cdMaterial is null or A14.L03_CD_MATERIAL = @cdMaterial)
group by A14.L03_CD_MATERIAL, A12.A12_TX_DESCRICAO
order by A14.L03_CD_MATERIAL, A12.A12_TX_DESCRICAO

END


/*
retorno lista<materiais> 
						cdMaterial		varchar(08)
						txEmbalagem		varchar(50)
						nrPesoKg		smallmoney
						nrPesoGr		smallmoney
*/