CREATE OR REPLACE TABLE xmppmaster.local_glpi_machines (
    `id` int NOT NULL, primary key(id),
    `entities_id` int(10) NOT NULL DEFAULT 0,
    `name` varchar(255) NULL DEFAULT NULL,
    `is_template` tinyint(4) NOT NULL DEFAULT 0,
    `is_deleted` tinyint(4) NOT NULL DEFAULT 0
)ENGINE=FEDERATED DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CONNECTION='itsm_federated/glpi_computers';

CREATE OR REPLACE TABLE xmppmaster.local_glpi_filters (
    `id` int NOT NULL, primary key(id),
    `states_id` int(10) NOT NULL DEFAULT 0,
    `entities_id` int(10) NOT NULL DEFAULT 0,
    `computertypes_id` int(10) NOT NULL DEFAULT 0,
    `autoupdatesystems_id` int(10) NOT NULL DEFAULT 0
)ENGINE=FEDERATED DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CONNECTION='itsm_federated/glpi_computers';

-- (>= glpi 9.5)
CREATE OR REPLACE TABLE xmppmaster.local_glpi_items_softwareversions(
    `id` int NOT NULL, primary key(id),
    `items_id` int NOT NULL DEFAULT 0,
    `itemtype` varchar(100) NOT NULL,
    `softwareversions_id` int NOT NULL DEFAULT 0
)ENGINE=FEDERATED DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CONNECTION='itsm_federated/glpi_items_softwareversions';

CREATE OR REPLACE TABLE xmppmaster.local_glpi_softwareversions (
    `id` int NOT NULL, primary key(id),
    `softwares_id` int NOT NULL DEFAULT 0,
    `name` varchar(255) DEFAULT NULL,
    `comment` text DEFAULT NULL
)ENGINE=FEDERATED DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CONNECTION='itsm_federated/glpi_softwareversions';


CREATE OR REPLACE TABLE xmppmaster.local_glpi_softwares(
    `id` int not null, primary key(id),
    `name` varchar(255) null default NULL,
    `comment` text null default null
)ENGINE=FEDERATED DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci CONNECTION='itsm_federated/glpi_softwares';
