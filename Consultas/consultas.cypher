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