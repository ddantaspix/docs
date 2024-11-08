use [sco_desenv]
GO

---------------------------------------------------------------------------------------------------------------------------------------------------
-- TABELAS
---------------------------------------------------------------------------------------------------------------------------------------------------

/****** Object:  Table SCO_C41_LOTES   Script Date: 18/10/2024 11:51:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------
ALTER TABLE SCO_C41_LOTES
 ADD 
   C41_DT_GERACAO_DOC DATETIME NULL,
   C41_NR_DOC_TEMP INT NULL;

GO

---------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURES
---------------------------------------------------------------------------------------------------------------------------------------------------


/****** Object: Procedure ISC_SP_EVENTO_RECOLHIMENTO_EXISTE   Script Date: 18/10/2024 11:51:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_EVENTO_RECOLHIMENTO_EXISTE

AS
BEGIN
	DECLARE @ID_EVENTO_RECOLHIMENTO AS INT = 13;
		
	SELECT 1 FROM SCO_C67_EVENTOS_NATUREZA_DOCUMENTOS 
		WHERE C36_ID_EVENTO = @ID_EVENTO_RECOLHIMENTO	
END 


/****** Object: Procedure ISC_SP_DOCUMENTOS_MATERIAIS_BUSCAR_LISTA   Script Date: 18/10/2024 11:51:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[ISC_SP_DOCUMENTOS_MATERIAIS_BUSCAR_LISTA]
	
AS 
BEGIN 

	DECLARE @ID_EVENTO_RECOLHIMENTO AS INT = 13;
	DECLARE @TIPO_OF_PRODUCAO TINYINT = 1;
	DECLARE	@TIPO_OF_TROCA TINYINT = 2;
	DECLARE	@TIPO_OF_AVULSA_PRODUCAO TINYINT = 3;
	DECLARE	@TIPO_OF_AVULSA_TROCA TINYINT = 4;
	DECLARE @STATUS_LOTE_RECOLHIDO TINYINT = 2;
	DECLARE @STATUS_LOTE_PESADO TINYINT = 3;
	DECLARE @CD_USUARIO CHAR(8) = 'SEMCOSTU';


	SELECT 
		 C41.C40_ID_OF AS IdOf, 
		 C41.C41_ID_LOTE AS IdLote,
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

GO


/****** Object: Procedure ISC_SP_DATA_NUMERO_TEMP_LOTE_ALTERAR   Script Date: 18/10/2024 11:51:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------------------------------------------------
CREATE PROCEDURE ISC_SP_DATA_NUMERO_TEMP_LOTE_ALTERAR
(
	@IdLote				INT,
	@IdOf				INT,
	@nrSequencialDocumento INT,
	@dataInclusaoDocumento DATETIME
)
AS
BEGIN
	
	UPDATE SCO_C41_LOTES 
	SET C41_DT_GERACAO_DOC = @dataInclusaoDocumento, C41_NR_DOC_TEMP = @nrSequencialDocumento
	WHERE C41_ID_LOTE = @IdLote AND C40_ID_OF = @IdOf
END 
GO