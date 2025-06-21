// 1
MATCH (cat:CategoriaAmeaca {nome: 'Criticamente em Perigo'})<-[:CLASSIFICADA_COMO]-(e:Especie)-[:OCORRE_EM]->(l:Localizacao)
WHERE e.endemica_brasil = 'Sim' 
  AND NOT (e)-[:CONTEMPLADA_NO]->(:PAN)
  
// Agrupa os resultados por bioma para análise
WITH l.bioma AS bioma, collect(DISTINCT e.nome) AS especiesSemProtecao
RETURN 
  bioma, 
  size(especiesSemProtecao) AS totalEspeciesCriticasSemPan,
  especiesSemProtecao
ORDER BY totalEspeciesCriticasSemPan DESC

// 2
MATCH (p:PAN)<-[:CONTEMPLADA_NO]-(e:Especie)

// Segue para o relacionamento de risco para obter a tendência populacional
MATCH (e)-[r:CLASSIFICADA_COMO]->(:CategoriaAmeaca)

// Agrupa por PAN e conta a ocorrência de cada tendência populacional
WITH p, r.tendencia_populacional AS tendencia, count(e) AS totalEspecies
ORDER BY p.nome, tendencia

// Retorna um mapa de tendências para cada PAN
RETURN 
  p.nome_fantasia AS planoDeAcao, 
  collect({tendencia: tendencia, total: totalEspecies}) AS distribuicaoTendencia



// 3
MATCH (e:Especie)-[r:CLASSIFICADA_COMO]->()
WHERE r.tendencia_populacional = 'Declinando'

// Garante que essa espécie ESTÁ conectada a um PAN já finalizado
AND (e)-[:CONTEMPLADA_NO]->(:PAN {status: 'Finalizado'})

// Garante que essa espécie NÃO ESTÁ conectada a nenhum PAN em execução
AND NOT (e)-[:CONTEMPLADA_NO]->(:PAN {status: 'Em execução'})

// Retorna as espécies que atendem a todos esses critérios complexos
RETURN 
  e.nome AS especieEmRisco,
  e.familia AS familia,
  e.grupo AS grupo
ORDER BY e.nome


// 4
MATCH (p:PAN {status: 'Em execução'})

// Encontra todos os biomas relacionados ao PAN, direta ou indiretamente
OPTIONAL MATCH (p)-[:VIGENTE_EM]->(l_direta:Localizacao)
OPTIONAL MATCH (p)<-[:CONTEMPLADA_NO]-(e:Especie)-[:OCORRE_EM]->(l_indireta:Localizacao)
WITH p, 
     collect(DISTINCT l_direta.bioma) + collect(DISTINCT l_indireta.bioma) AS biomas

// "Flatten" via UNWIND
UNWIND biomas AS bioma
WITH p, bioma WHERE bioma IS NOT NULL
WITH p, collect(DISTINCT bioma) AS biomasUnicos

// Encontra a categoria de ameaça mais alta entre as espécies do PAN
MATCH (p)<-[:CONTEMPLADA_NO]-(especie:Especie)-[:CLASSIFICADA_COMO]->(cat:CategoriaAmeaca)
WITH p, biomasUnicos, cat.nome AS categoria

// Define uma ordem de severidade para as categorias
WITH p, biomasUnicos,
     CASE categoria
       WHEN 'Criticamente em Perigo' THEN 3
       WHEN 'Em Perigo' THEN 2
       WHEN 'Vulnerável' THEN 1
       ELSE 0
     END AS nivelSeveridade

// Agrupa por PAN para encontrar o nível máximo de severidade
WITH p, biomasUnicos, max(nivelSeveridade) AS maxNivel

// Traduz o nível de volta para o nome da categoria
WITH p, biomasUnicos,
     CASE maxNivel
       WHEN 3 THEN 'Criticamente em Perigo'
       WHEN 2 THEN 'Em Perigo'
       WHEN 1 THEN 'Vulnerável'
       ELSE 'Pouco Preocupante ou Inferior'
     END AS ameacaMaxima

RETURN 
  p.nome_fantasia AS planoDeAcao,
  ameacaMaxima,
  biomasUnicos AS biomasDeImpacto
ORDER BY size(biomasDeImpacto) DESC


// 5
MATCH (e:Especie)
// Obtém a ameaça da propriedade do relacionamento
OPTIONAL MATCH (e)-[r:CLASSIFICADA_COMO]->()
// Obtém a lista de ações de conservação dos nós conectados
OPTIONAL MATCH (e)-[:ALVO_DE]->(ac:AcaoConservacao)

WITH e, r.ameaca AS ameacas, collect(DISTINCT ac.nome) AS acoes

// Filtra para mostrar apenas espécies que têm ameaças identificadas e alguma ação associada
WHERE ameacas IS NOT NULL AND size(acoes) > 0

RETURN
  e.nome AS especie,
  ameacas,
  acoes
ORDER BY e.nome