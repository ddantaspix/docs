
USE [apn]
GO

create procedure [dbo].[ISC_SP_ALMOXARIFADO_LOCAL_BUSCAR]
(
	@idAlmoxarifado int,
	@cdLocal		char(04)
)
as
begin
	select	A04_ID_LOCAL		as ID_LOCAL,
			A02_ID_ALMOX_PROCES	as ID_ALMOX_PROCES,
			A04_CD_LOCAL		as CD_LOCAL,
			A04_TX_DESCRICAO	as TX_DESCRICAO
	from	APN_A04_LOCAIS
	where	A02_ID_ALMOX_PROCES = @idAlmoxarifado
	and		A04_CD_LOCAL = @cdLocal
end

GO



/****** Object:  StoredProcedure [dbo].[ISC_SP_CAIXA_BUSCAR_LISTA]    Script Date: 04/09/2024 11:34:50 ******/
------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[ISC_SP_CAIXA_BUSCAR_LISTA]
(
	@cdMaterial varchar(8)
)
AS
BEGIN
	
		DECLARE @ST_PECA AS varchar(1) = 'D'

		select	A15.A15_ID_ESTOQUE	AS ID_ESTOQUE,
			A15.A02_ID_ALMOX_PROCES AS ID_ALMOX_PROCES,
			A14.L03_CD_MATERIAL		AS CD_MATERIAL, 
			VW13.L03_TX_DESCRICAO	AS TX_MATERIAL,
			A14.A14_ID_ROMANEIO		AS ID_ROMANEIO, 
			A14.A14_NR_ROMANEIO		AS NR_ROMANEIO, 
			A14.A14_DT_ENTRADA		AS DT_ENTRADA,
			A04.A04_ID_LOCAL		AS ID_LOCAL,
			A04.A04_CD_LOCAL		AS CD_LOCAL,
			A04.A04_TX_DESCRICAO	AS TX_LOCAL,		
			A15.A15_NR_CAIXA		AS NR_CAIXA, 
			A15.A15_NR_PESO_BRUTO	AS NR_PESO_BRUTO,
			A15.A15_NR_PESO_LIQUIDO AS NR_PESO_LIQUIDO,
			A15.A15_NR_TARA			AS NR_TARA,		
			A15.A15_NR_QTDE			AS NR_QTDE, 
			A15.A15_NR_NUM_PECA		AS NR_NUM_PECA,
			A12.A12_ID_EMBALAGEM	AS ID_EMBALAGEM, 
			A12.A12_TX_DESCRICAO	AS TX_EMBALAGEM,
			A14.A14_NR_LOTE			AS NR_LOTE, 
			A14.A14_TX_OBSERVACOES	AS TX_OBSERVACOES		 
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
	and		A14.L03_CD_MATERIAL = @cdMaterial
	and		A15.A19_ST_PECA =  @ST_PECA --constante caixa disponível
	order by A14_NR_ROMANEIO,A15_NR_CAIXA,A04_CD_LOCAL

END

GO


/****** Object:  StoredProcedure [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_EXISTE_LOCAL]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_EXISTE_LOCAL]
(
	@cdProcesso varchar(8)
)
AS
BEGIN
	
select	A02.A04_ID_LOCAL AS ID_LOCAL,
		A04.A04_TX_DESCRICAO AS TX_DESCRICAO 
from	APN_A02_ALMOX_PROCES A02  
inner join APN_A04_LOCAIS A04
on		A02.A04_ID_LOCAL = A04.A04_ID_LOCAL
and		A02.A02_ID_ALMOX_PROCES = @CdProcesso -- CdProcesso

END

GO

/****** Object:  StoredProcedure [dbo].[ISC_SP_TIPO_MOVIMENTA_MATERIAL_LER]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_TIPO_MOVIMENTA_MATERIAL_LER]
(
	@idMovimento int
)
AS
BEGIN
	
select	 A09_TP_DOCUMENTO AS TP_DOCUMENTO
		,A09_IN_MOVIMENTA_MATERIAIS AS IN_MOVIMENTA_MATERIAIS
from 	APN_A09_MOVIMENTOS
where 	A09_ID_MOVIMENTO = @idMovimento 

END

GO

/****** Object:  StoredProcedure [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_LER]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_LER]
(
	@almoxProcesso  int
)
AS
BEGIN

select	  M07_CD_CCUSTO AS CD_CCUSTO
		, M06_NR_CONTA AS NR_CONTA
		, A02_IN_PROCESSO AS IN_PROCESSO
from 	APN_A02_ALMOX_PROCES
where 	A02_ID_ALMOX_PROCES = @almoxProcesso

END

GO

--***********************************************
--***Início da validação da caixa (idEstoque) ***
--***********************************************



/****** Object:  StoredProcedure [dbo].[ISC_SP_ESTOQUE_ALMOXARIFADO_LER]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_ESTOQUE_ALMOXARIFADO_LER]
(
	@idEstoque  int
)
AS
BEGIN
	
select	A02_ID_ALMOX_PROCES AS ID_ALMOX_PROCES
from	APN_A15_ESTOQUES
where	A15_ID_ESTOQUE = @idEstoque

END

GO

/****** Object:  StoredProcedure [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_LER]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_ALMOXARIFADO_PROCESSO_LER]
(
	@almoxProcesso  int
)
AS
BEGIN

select	  M07_CD_CCUSTO AS CD_CCUSTO
		, M06_NR_CONTA AS NR_CONTA
		, A02_IN_PROCESSO AS IN_PROCESSO
from 	APN_A02_ALMOX_PROCES
where 	A02_ID_ALMOX_PROCES = @almoxProcesso

END


GO

/****** Object:  StoredProcedure [dbo].[ISC_SP_VERIFICA_CAIXA_DISPONIVEL]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_VERIFICA_CAIXA_DISPONIVEL]
(
	@cdAlmoxarifado int,
	@idEstoque int
)
AS
BEGIN

DECLARE @ST_PECA AS varchar(1) = 'A'

select	A15_ID_ESTOQUE AS ID_ESTOQUE,
		A14_NR_ROMANEIO AS NR_ROMANEIO,
		A14.L03_CD_MATERIAL AS CD_MATERIAL,
		L03_TX_DESCRICAO AS TX_DESC
from	APN_A14_ROMANEIOS A14
inner join APN_A15_ESTOQUES A15
on		A14.A14_ID_ROMANEIO = A15.A14_ID_ROMANEIO 	
inner join APN_A04_LOCAIS A04
on		A15.A04_ID_LOCAL = A04.A04_ID_LOCAL
inner join APN_A13_MATERIAIS_PROCES_VIEW VW13 
on		A14.L03_CD_MATERIAL = VW13.L03_CD_MATERIAL 
and		A15.A02_ID_ALMOX_PROCES = VW13.A02_ID_ALMOX_PROCES 
where	A15.A02_ID_ALMOX_PROCES = '5' --cdAlmoxarifado (fio comprado)
and		A15.A19_ST_PECA = @ST_PECA --constante caixa aguardando confirmação
and		A15.A15_ID_ESTOQUE = 1052384--idEstoque
END

GO

/****** Object:  StoredProcedure [dbo].[ISC_SP_VERIFICA_MOVIMENTACAO]   Script Date: 05/09/2024 11:51:02 ******/
CREATE PROCEDURE [dbo].[ISC_SP_VERIFICA_MOVIMENTACAO]
(
	@idEstoque	int
)
AS 
BEGIN

select	count(isnull(A18_ID_MOVIMENTACAO,0)) AS N_MOVIMENTACOES
from	APN_A18_MOVIMENTACOES
where	(A18_ST_LIBERADO_MATERIAIS = 'N' or A18_ST_LIBERADO_MATERIAIS is null)
and		A09_ID_MOVIMENTO in (1,3,5,6,9,10) -- constantes
and		A15_ID_ESTOQUE = @idEstoque

END


GO

create procedure [dbo].[ISC_SP_CAIXA_REQUISICAO_INCLUIR]  
(  
	@idMovimento			int,
	@idEstoque				int,
	@idAlmoxarifadoOrigem	int,
	@idAlmoxarifadoDestino	int,
	@cdUsuario				char(08),
	@idMovimentacao 		int output
)  
as
begin
	declare @ID_STATUS_PECA_AGUARDANDO_CONFIRMACAO char(01) = 'A'
	
	insert APN_A18_MOVIMENTACOES 
	(
		A09_ID_MOVIMENTO, 
		A15_ID_ESTOQUE, 
		A18_ID_ALMOX_ORIGEM, 
		A18_ID_ALMOX_DESTINO, 
		A11_ID_MOTIVO, 
		A18_DT_MOVIMENTO,
		A18_NR_PESO_LIQUIDO, 
		A18_NR_QTDE_EMBALAGEM, 
		A18_ST_EXPORTA_MATERIAIS, 
		PP_TX_USER_STAMP, 
		A18_ST_LIBERADO_MATERIAIS
	) 
	select	@idMovimento, 
			A15_ID_ESTOQUE, 
			@idAlmoxarifadoOrigem, 
			@idAlmoxarifadoDestino, 
			null, 
			convert(varchar(20),getdate(),101),
			A15_NR_PESO_LIQUIDO, 
			A15_NR_QTDE, 
			'N', 
			@cdUsuario,
			'N'
	from	APN_A15_ESTOQUES		
	where	A15_ID_ESTOQUE = @idEstoque
	
	select	@idMovimentacao = @@IDENTITY	
		
	update	APN_A15_ESTOQUES
	set		A02_ID_ALMOX_PROCES = @idAlmoxarifadoDestino,
			A19_ST_PECA = @ID_STATUS_PECA_AGUARDANDO_CONFIRMACAO,
			PP_TX_USER_STAMP = @cdUsuario
	where	A15_ID_ESTOQUE = @idEstoque
end

GO