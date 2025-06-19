/////////////CRIAÇÃO DE CONSTRAINTS E ÍNDICES//////////////

CREATE CONSTRAINT IF NOT EXISTS FOR (e:Especie) REQUIRE e.id_especie IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (l:Localizacao) REQUIRE l.id_localizacao IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (p:PAN) REQUIRE p.id_pan IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (ac:AcaoConservacao) REQUIRE ac.id_conservacao IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (po:Portaria) REQUIRE po.id_portaria IS UNIQUE;
CREATE CONSTRAINT IF NOT EXISTS FOR (cat:CategoriaAmeaca) REQUIRE cat.nome IS UNIQUE;


///////////// CRIAÇÃO DOS NÓS //////////////

// -- Especie --
LOAD CSV WITH HEADERS FROM 'file:///especie.csv' AS row
CREATE (:Especie {
  id_especie: row.id_especie,
  nome: row.nome,
  filo: row.filo,
  ordem: row.ordem,
  classe: row.classe,
  familia: row.familia,
  genero: row.genero,
  grupo: row.grupo,
  endemica_brasil: row.endemica_brasil,
  migratoria: row.migratoria
});

// -- Localizacao --
LOAD CSV WITH HEADERS FROM 'file:///localizacao.csv' AS row
CREATE (:Localizacao {
  id_localizacao: row.id_localizacao,
  estado: row.estado,
  regiao: row.regiao,
  bioma: row.bioma
});

// -- PAN (Plano de Ação Nacional) --
LOAD CSV WITH HEADERS FROM 'file:///pan.csv' AS row
CREATE (:PAN {
  id_pan: row.id_pan,
  nome: row.pan_nome,
  nome_completo: row.pan_nome_completo,
  nome_fantasia: row.pan_nome_fantasia,
  abreviacao_taxonomica: row.pan_abreviacao_taxonomica,
  ciclo: row.pan_ciclo,
  status: row.pan_status,
  inicio_data: CASE WHEN row.pan_inicio_data IS NOT NULL AND row.pan_inicio_data <> "NULL" THEN date(row.pan_inicio_data) ELSE null END,
  fim_data: CASE WHEN row.pan_fim_data IS NOT NULL AND row.pan_fim_data <> "NULL" THEN date(row.pan_fim_data) ELSE null END,
  abrangencia_geografica: row.pan_abrangencia_geografica
});

// -- AcaoConservacao (Antigo "Conservacao") --
LOAD CSV WITH HEADERS FROM 'file:///conservacao.csv' AS row
CREATE (:AcaoConservacao {
  id_conservacao: toString(row.id_conservacao),
  nome: row.nome
});

// -- Portaria --
LOAD CSV WITH HEADERS FROM 'file:///portaria.csv' AS row
CREATE (:Portaria {
  id_portaria: row.id_portaria,
  pan_status_legal: row.pan_status_legal,
  data_da_portaria_vigente_do_PAN: date(row.data_da_portaria_vigente_do_PAN)
});

// -- CategoriaAmeaca (Nó criado a partir do CSV de risco) --
// Este passo lê o arquivo de risco apenas para extrair as categorias únicas.
LOAD CSV WITH HEADERS FROM 'file:///risco.csv' AS row
WITH row.categoria AS categoriaNome
WHERE categoriaNome IS NOT NULL
MERGE (:CategoriaAmeaca {nome: categoriaNome});


///////////// PARTE 3: CRIAÇÃO DOS RELACIONAMENTOS //////////////
LOAD CSV WITH HEADERS FROM 'file:///risco.csv' AS row
MATCH (e:Especie {id_especie: row.id_especie})
MATCH (cat:CategoriaAmeaca {nome: row.categoria})
MERGE (e)-[r:CLASSIFICADA_COMO]->(cat)
  ON CREATE SET
    r.tendencia_populacional = row.tendencia_populacional,
    r.ameaca = row.ameaca,
    r.possivelmente_extinta = row.possivelmente_extinta,
    r.uso = row.uso;

// -- Especie -> AcaoConservacao --
LOAD CSV WITH HEADERS FROM 'file:///especie-conservacao.csv' AS row
MATCH (e:Especie {id_especie: row.id_especie})
MATCH (ac:AcaoConservacao {id_conservacao: row.id_conservacao})
MERGE (e)-[:ESTA_EM]->(ac);

// -- Especie -> Localizacao --
LOAD CSV WITH HEADERS FROM 'file:///especie-localizacao.csv' AS row
MATCH (e:Especie {id_especie: row.id_especie})
MATCH (l:Localizacao {id_localizacao: row.id_localizacao})
MERGE (e)-[:OCORRE_EM]->(l);

// -- PAN -> Localizacao --
LOAD CSV WITH HEADERS FROM 'file:///pan-localizacao.csv' AS row
MATCH (p:PAN {id_pan: row.id_pan})
MATCH (l:Localizacao {id_localizacao: row.id_localizacao})
MERGE (p)-[:VIGENTE_EM]->(l);

// -- Especie -> PAN --
LOAD CSV WITH HEADERS FROM 'file:///especie-pan.csv' AS row
MATCH (e:Especie {id_especie: row.id_especie})
MATCH (p:PAN {id_pan: row.id_pan})
MERGE (e)-[:CONTEMPLADA_NO]->(p);

// -- PAN -> Portaria --
LOAD CSV WITH HEADERS FROM 'file:///portaria.csv' AS row
WHERE row.id_pan IS NOT NULL
MATCH (p:PAN {id_pan: row.id_pan})
MATCH (prt:Portaria {id_portaria: row.id_portaria})
MERGE (p)-[:REGULADO_POR]->(prt);

