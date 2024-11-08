use materiais
GO

---------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURES
---------------------------------------------------------------------------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[ISC_SP_DADOS_DOCUMENTO_LER]    Script Date: 04/10/2024 15:09:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ISC_SP_DADOS_DOCUMENTO_LER]

AS 
BEGIN 

DECLARE @ID_EVENTO_RECOLHIMENTO AS INT = 13;
DECLARE @TIPO_OF_PRODUCAO TINYINT = 1;
DECLARE	@TIPO_OF_TROCA TINYINT = 2;
DECLARE	@TIPO_OF_AVULSA_PRODUCAO TINYINT = 3;
DECLARE	@TIPO_OF_AVULSA_TROCA TINYINT = 4;
DECLARE @STATUS_LOTE_RECOLHIDO TINYINT = 2;
DECLARE @STATUS_LOTE_PESADO TINYINT = 3;
DECLARE @CD_USUARIO CHAR(8) = 'SEMCOSTU'

SELECT
	 C41.C40_ID_OF As IdOf,
	 C41.C41_ID_LOTE As IdLote,
     C41.C38_ID_STATUS_LOTE,
     C40.C37_ID_TIPO_OF,
     C20.C20_CD_PRODUTO As Material,
     C41.C41_NR_QTDE_PECAS AS Quantidade, 
     C67.C67_CD_CENTRO_CUSTO_ATENDE AS CentroCustoAtende, 
     C67.C67_CD_CENTRO_CUSTO_RECEBE AS CentroCustoRecebe, 
     C67.C67_CD_NATUREZA AS NrNatureza, 
     C67.C67_NR_CONTA_ATENDE AS ContaContabilAtende, 
     C67.C67_NR_CONTA_RECEBE AS ContaContabilRecebe,
	 @CD_USUARIO AS CdUsuario

    FROM SCO_C41_LOTES C41 
INNER JOIN SCO_C40_OF C40
ON C40.C40_ID_OF = C41.C40_ID_OF
INNER JOIN SCO_C67_EVENTOS_NATUREZA_DOCUMENTOS C67
ON C67.C37_ID_TIPO_OF = C40.C37_ID_TIPO_OF
INNER JOIN SCO_C20_FICHAS C20
ON C20.C20_ID_FICHA = C40.C20_ID_FICHA
WHERE C40.C37_ID_TIPO_OF IN (@TIPO_OF_PRODUCAO, @TIPO_OF_TROCA, @TIPO_OF_AVULSA_PRODUCAO, @TIPO_OF_AVULSA_TROCA) -- TIPOS DE OF
AND C67.C36_ID_EVENTO = @ID_EVENTO_RECOLHIMENTO
AND C41.C38_ID_STATUS_LOTE IN (@STATUS_LOTE_RECOLHIDO,@STATUS_LOTE_PESADO)
AND C41_DT_GERACAO_DOC IS NULL
AND C41_NR_DOC_TEMP IS NULL

END


/****** Object:  StoredProcedure [dbo].[ISC_SP_MATERIAL_PARAMETRO_LER]    Script Date: 04/10/2024 15:09:39 ******/
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
	SELECT	M02_TX_PARAMETRO as TX_PARAMETRO
	FROM	MAT_M02_PARAMETROS
	WHERE	M02_NR_PARAMETRO = @nrParametro
END
GO


/****** Object:  StoredProcedure [dbo].[ISC_SP_PARAMETRO_ALTERAR]    Script Date: 04/10/2024 15:09:39 ******/
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
	
	SELECT @unidade = M06_SG_UNIDADE WHERE L03_CD_MATERIAL = material
	
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
	
	-- --BUSCA A EMPRESA DO CENTRO DE CUSTO E CONTA ATENDE (ALMOXATRIFADO ORIGEM)
	-- SELECT	DISTINCT @empresa = M30_CD_EMPRESA
	-- FROM	MAT_M29_SALDOS M29
	-- INNER JOIN MAT_M07_CENTROS_CUSTO M07
	-- ON		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	-- WHERE	M29.M07_CD_CCUSTO = @centroCustoAtende
	-- AND		M29.M09_NR_CONTA  = @contaContabilAtende
	-- AND 	M07.M07_TP_CCUSTO = @TP_CCUSTO
	

	--BUSCA A EMPRESA DO CENTRO DE CUSTO E CONTA RECEBE (ALMOXATRIFADO DESTINO)
	 SELECT	DISTINCT @empresa = M30_CD_EMPRESA
	 FROM	MAT_M29_SALDOS M29
	 INNER JOIN MAT_M07_CENTROS_CUSTO M07
	 ON		M29.M07_CD_CCUSTO = M07.M07_CD_CCUSTO
	 WHERE	M29.M07_CD_CCUSTO = @centroCustoRecebe
	 AND		M29.M09_NR_CONTA  = @contaContabilRecebe
	 AND 	M07.M07_TP_CCUSTO = @TP_CCUSTO
	 

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
