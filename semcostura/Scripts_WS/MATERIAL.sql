use [materiais]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURES
---------------------------------------------------------------------------------------------------------------------------------------------------
/****** Object:  StoredProcedure [dbo].[ISC_SP_PROXIMO_DOCUMENTO_BUSCAR]    Script Date: 04/10/2024 15:09:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_MATERIAL_PARAMETRO_LER
(
	@nrParametro SMALLINT
)
AS
BEGIN
	--NÚMERO DO PRÓXIMO DOCUMENTO A SER GERADO
	SELECT	M02_TX_PARAMETRO as TX_PARAMETRO
	FROM	MAT_M02_PARAMETROS
	WHERE	M02_NR_PARAMETRO = @nrParametro
END
GO



/****** Object:  StoredProcedure [dbo].[ISC_SP_MATERIAIS_DOCUMENTO_INCLUIR]    Script Date: 04/10/2024 15:09:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_MATERIAIS_DOCUMENTO_INCLUIR
(
	@nrParametroSequencial		INT,
	@material					CHAR(08),
	@digitoVerificador			CHAR(01),
	@unidade					CHAR(02),
	@quantidade					SMALLMONEY,
	@centroCustoAtende			CHAR(05),
	@contaContabilAtende		CHAR(06),
	@centroCustoRecebe			CHAR(05),
	@contaContabilRecebe		CHAR(06)
)
as
BEGIN
	
	DECLARE @NR_POSICAO AS INT = 1
	DECLARE @VL_UNITARIO AS INT = 0
	
	INSERT MAT_M48_DOC_MATERIAIS_BAT 
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
	VALUES 
	(
		@nrParametroSequencial,
		@NR_POSICAO,
		@material,
		@digitoVerificador,
		@unidade,
		@quantidade,
		@centroCustoAtende,
		@contaContabilAtende,
		@centroCustoRecebe,
		@contaContabilRecebe,
		@VL_UNITARIO,
		@VL_UNITARIO
	)
END
GO


/****** Object:  StoredProcedure [dbo].[ISC_SP_DOCUMENTO_INCLUIR]    Script Date: 04/10/2024 15:09:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_DOCUMENTO_INCLUIR
(
	@nrParametroSequencial 	INT,
	@nrNatureza				INT,
	@centroCustoAtende		CHAR(05),
	@contaContabilAtende	CHAR(06),
	@centroCustoRecebe		CHAR(05),
	@contaContabilRecebe	CHAR(06),
	@cdUsuario				CHAR(08),
	@dataInserida	DATETIME output
	
)
AS
BEGIN
	DECLARE	@empresa	tinyint

	DECLARE @TX_OBSERVACAO as char(1) = ''
	DECLARE @ST_VALOR AS char(1) = 'N'
	DECLARE @VL_TOTAL_DOC AS int = 0
	DECLARE @ST_SITUACAO AS char(1) = 'N'
	DECLARE @IN_REPROCESSO AS char(1) = 'S'
	DECLARE @TP_CCUSTO AS char(1) = 'C'

	SELECT @dataInserida = GETDATE()
	
	--BUSCA A EMPRESA DO CENTRO DE CUSTO E CONTA ATENDE (ALMOXATRIFADO ORIGEM)
	SELECT	DISTINCT @empresa = M30_CD_EMPRESA
	FROM	MAT_M29_SALDOS M29
	INNER JOIN MAT_M07_CENTROS_CUSTO M07
	ON		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	WHERE	M29.M07_CD_CCUSTO = @centroCustoAtende
	AND		M29.M09_NR_CONTA  = @contaContabilAtende
	AND 	M07.M07_TP_CCUSTO = @TP_CCUSTO
	
	--UNION
	
	-- --BUSCA A EMPRESA DO CENTRO DE CUSTO E CONTA RECEBE (ALMOXATRIFADO DESTINO)
	-- SELECT	DISTINCT @empresa = M30_CD_EMPRESA
	-- FROM	MAT_M29_SALDOS M29
	-- INNER JOIN MAT_M07_CENTROS_CUSTO M07
	-- ON		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	-- WHERE	M29.M07_CD_CCUSTO = @centroCustoRecebe
	-- AND		M29.M09_NR_CONTA  = @contaContabilRecebe
	-- AND 	M07.M07_TP_CCUSTO = @TP_CCUSTO

	INSERT MAT_M47_DOCUMENTOS_BAT 
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
	VALUES
	(
		@nrParametroSequencial,
		@nrNatureza,
		@nrParametroSequencial,
		@empresa,
		@dataInserida,
		@dataInserida,
		@cdUsuario,
		@TX_OBSERVACAO,
		@ST_VALOR,
		@VL_TOTAL_DOC,
		@ST_SITUACAO,
		@IN_REPROCESSO,
		NULL
	)
END

GO


/****** Object:  StoredProcedure [dbo].[ISC_SP_PROXIMO_DOCUMENTO_ATUALIZAR]    Script Date: 04/10/2024 15:09:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_PARAMETRO_ALTERAR
(
	@txParametro	INT,
	@nrParametro	INT
)
AS
BEGIN
	UPDATE	MAT_M02_PARAMETROS
	SET		M02_TX_PARAMETRO = @txParametro
	WHERE	M02_NR_PARAMETRO = @nrParametro
END
GO