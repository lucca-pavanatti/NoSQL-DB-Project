# NoSQL-DB-Project

### Resumo

Esse trabalho tem como objetivo analisar a implementação e a efetividade dos Planos de Ação Nacional para a Conservação de Espécies Ameaçadas de Extinção (PANs) no Brasil. Utilizando bancos de dados públicos disponibilizados pelo ICMBio, foi possível realizar um levantamento sobre a abrangência geográfica e taxonômica dos planos, bem como avaliar lacunas nas ações de conservação voltadas para espécies criticamente ameaçadas.  
O foco da análise está na interseção entre os dados de risco de extinção, presença em biomas brasileiros e a existência (ou ausência) de políticas públicas e ações associadas a essas espécies.

### Objetivo de Desenvolvimento Sustentável (ODS) relacionado

O trabalho está diretamente relacionado ao **ODS 15 – Vida Terrestre**, que visa:

> "proteger, recuperar e promover o uso sustentável dos ecossistemas terrestres, gerir de forma sustentável as florestas, combater a desertificação, deter e reverter a degradação da terra e deter a perda de biodiversidade".

Em especial, ele contribui com as metas:

- **15.5**: Tomar medidas urgentes e significativas para reduzir a degradação de habitats naturais, deter a perda de biodiversidade e proteger e evitar a extinção de espécies ameaçadas.
- **15.9**: Integrar os valores da biodiversidade e dos ecossistemas nos processos de planejamento e desenvolvimento nacionais.


### Justificativa: Cenário x Banco NoSql utilizado

Diante do cenário apresentado, que demanda forte representação de relacionamentos complexos, consultas frequentes envolvendo múltiplos níveis de conexão entre entidades, integridade relacional e suporte transacional com alto desempenho, a escolha mais adequada entre os bancos propostos (MongoDB, DuckDB ou Neo4J) é o Neo4J, um banco de dados orientado a grafos.

A principal justificativa para essa escolha se baseia na estrutura natural dos dados e nas exigências de acesso do problema. O modelo atual em PostgreSQL representa uma malha densa de relações entre entre entidades como Especie, Localizacao, Plano_de_Acao_Nacional, Risco, Conservacao e Portaria. Tais entidades estão fortemente conectadas por meio de chaves estrangeiras e tabelas de junção, como Especie_PAN, Especie_Conservacao, Especie_Localizacao e PAN_Localizacao. Além disso, consultas complexas frequentemente exigem múltiplos joins, tornando o desempenho e a legibilidade das consultas um desafio crescente em um banco relacional tradicional. Assim, o Neo4J, por sua natureza, armazena dados como nós (entidades) e arestas (relacionamentos), o que permite a modelagem direta e performática dessas conexões. Por exemplo, identificar todas as espécies endêmicas do Brasil (Especie.endemica_brasil = 'Sim') que estão vinculadas a um Plano_de_Acao_Nacional específico e habitam um determinado Bioma, e então explorar as ameaças (Risco.ameaca) associadas a elas, seria uma consulta muito mais natural e eficiente em um grafo. Ou seja, consultas que em bancos relacionais exigiriam múltiplas junções passam a ser expressas de forma intuitiva e eficiente na linguagem Cypher, própria do Neo4J.

Do ponto de vista da forma de armazenamento, o Neo4j armazena informações em um modelo de grafo nativo, onde cada relacionamento é uma entidade de primeira classe com suas próprias propriedades, se necessário. Isso é fundamentalmente diferente do MongoDB, que utiliza documentos JSON para agrupar dados, ou do DuckDB, que armazena dados em formato colunar, otimizado para agregações analíticas. A capacidade do Neo4j de manter ponteiros diretos entre nós e relacionamentos permite a navegação eficiente entre entidades mesmo em grafos grandes e profundos, exatamente como exige o cenário de "navegar conexões indiretas e múltiplos níveis de relacionamento".

Em relação à linguagem e processamento de consultas, o Neo4j utiliza Cypher, uma linguagem declarativa e gráfica projetada especificamente para consultar padrões de relacionamentos. O Cypher permite expressar consultas complexas de grafos de forma intuitiva, concisa e mais eficiente para identificar conexões indiretas e caminhos complexos, utilizando sintaxe baseada em ASCII art (e.g., (node)-[relationship]->(other_node)). Isso contrasta com o SQL tradicional, que se tornaria rapidamente verboso e menos performático para essas tarefas de "explorar entidades próximas" e "identificar padrões de relacionamento", ou com o modelo de agregações do MongoDB, que exigiria múltiplas operações de desnormalização ou lookup para simular junções profundas.

No que se refere ao processamento e controle de transações, o Neo4j possui suporte completo a propriedades ACID (Atomicidade, Consistência, Isolamento, Durabilidade), assim como o PostgreSQL. Isso garante que cada operação ou conjunto de operações seja executado integralmente, ou não seja executado, mantendo a integridade dos dados mesmo em falhas. Esse suporte é essencial para garantir a "integridade relacional e suporte transacional" exigidos, especialmente em operações críticas de atualização que envolvam múltiplas entidades e seus relacionamentos.

Além disso, o Neo4j conta com mecanismos robustos de recuperação e segurança. Para recuperação, oferece journaling (registro de transações) e checkpoints para garantir a durabilidade dos dados e a capacidade de restaurar o banco a um estado consistente após falhas. Para segurança, proporciona controle de acesso baseado em usuários e papéis, permitindo permissões granulares sobre nós, relacionamentos e propriedades. Também suporta criptografia de dados em repouso e em trânsito, garantindo a proteção da informação em todas as etapas da comunicação e armazenamento. Esses mecanismos são cruciais para a confiabilidade e proteção em aplicações de missão crítica.

Já o MongoDB, embora seja altamente flexível e escalável horizontalmente, não é ideal para cenários em que a relação entre dados é mais importante do que os próprios documentos, o que é o caso aqui. O modelo de documentos do MongoDB exigiria frequentemente duplicação de dados para otimização de leitura, ou o uso excessivo de referências que dificultam e penalizam a navegação por relacionamentos profundos. Já o DuckDB, por ser um banco colunar, é voltado a análises analíticas (OLAP) e processamento vetorizado de grandes volumes de dados em memória, e não atende bem as exigências transacionais nem de modelagem e navegação de relacionamentos complexos entre entidades do cenário.

Portanto, considerando todos esses aspectos: modelo de dados nativo para grafos, linguagem de consulta otimizada para relacionamentos, controle transacional ACID, alto desempenho em consultas relacionais profundas e robustez em segurança e recuperação, o Neo4j é a escolha mais apropriada para suportar o tipo de aplicação descrita, promovendo ganhos significativos em clareza, eficiência e escalabilidade nas operações com dados altamente conectados.

---

### Explicação das Consultas 
As cinco consultas desenvolvidas para o novo modelo exemplificam os benefícios da abordagem de grafo:

#### Consulta 1 (Espécies Críticas sem Proteção):
Importância Estratégica: Essa é a consulta de triagem mais urgente. Ela responde à pergunta: "Onde estão nossas falhas mais críticas?". Ao identificar espécies "Criticamente em Perigo" que não estão sob a guarda de nenhum Plano de Ação Nacional (PAN), a consulta aponta exatamente para onde a atenção e os recursos de conservação precisam ser direcionados com máxima prioridade.

---

#### Consulta 2 (Eficácia dos PANs):

Importância Estratégica: Essa consulta serve como um atestado de eficácia dos planos existentes. Ela pergunta: "Nossos planos de conservação estão focando nos problemas certos?". Ao analisar a distribuição da tendência populacional das espécies cobertas por cada PAN, pode-se avaliar se um plano está, de fato, concentrado em espécies em declínio (alto impacto) ou se está gastando recursos com espécies já estáveis (baixo impacto).

---

#### Consulta 3 (Eficiência dos PANs):

Importância Estratégica: Essa consulta identifica um alerta administrativo. Ela busca por espécies que estão em declínio, cuja proteção que tinham através de um PAN já expirou, e nenhuma nova proteção foi colocada em vigor. Para um formulador de políticas, esta é uma lista de falhas de continuidade que podem levar espécies à extinção por negligência burocrática.

---

#### Consulta 4 (Influência Geográfica):

Importância Estratégica: Essa consulta oferece uma visão de diferentes perspectivas sobre o impacto de um plano, respondendo à pergunta: "Qual é a verdadeira cobertura de um PAN?". Aqui, não basta saber quais espécies um plano cobre, mas também quais biomas e regiões ele influencia. A consulta ajuda a entender a abrangência e a relevância ecológica de cada plano, permitindo uma alocação de recursos mais informada.

---

#### Consulta 5 (Alinhamento Ameaça vs. Ação):

Importância Estratégica: Essa é uma consulta de alinhamento estratégico fundamental. Ela pergunta: "As nossas soluções correspondem aos nossos problemas?". Ao colocar as ameaças diagnosticadas para uma espécie lado a lado com as ações de conservação implementadas, a consulta expõe imediatamente as lacunas. Se a principal ameaça não tem uma ação de mitigação correspondente, o plano é falho, permitindo um refinamento da estratégias.

---

Em suma, cada aspecto da escolha pelo Neo4j, desde seu armazenamento nativo e linguagem de consulta até sua conformidade com ACID e a metodologia de modelagem aplicada, foi deliberadamente selecionado para satisfazer e exceder os requisitos de um cenário focado na exploração profunda e performática de relacionamentos complexos.