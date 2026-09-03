-- ============================================================
-- KT_CHARACTER — SCHÉMA SQL v3
-- PRÉREQUIS : table `users` fournie par `union`
-- ============================================================

CREATE TABLE IF NOT EXISTS `characters` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `unique_id`   VARCHAR(36)  NOT NULL,
    `firstname`   VARCHAR(50)  NOT NULL,
    `lastname`    VARCHAR(50)  NOT NULL,
    `dateofbirth` DATE         NOT NULL,
    `ped_model`   VARCHAR(60)  NOT NULL DEFAULT 'mp_m_freemode_01',
    `position`    JSON         DEFAULT NULL,
    `health`      INT          DEFAULT 200,
    `armor`       INT          DEFAULT 0,
    `is_dead`     TINYINT(1)   DEFAULT 0,
    `job`         VARCHAR(50)  DEFAULT 'unemployed',
    `job_grade`   INT          DEFAULT 0,
    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `last_played` TIMESTAMP    NULL DEFAULT NULL,
    `updated_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_unique_id` (`unique_id`),
    INDEX `idx_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_character` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier`  VARCHAR(60)  NOT NULL,
    `unique_id`   VARCHAR(36)  NOT NULL,
    `created_at`  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_user_char` (`identifier`, `unique_id`),
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_unique_id` (`unique_id`),
    CONSTRAINT `fk_uc_user` FOREIGN KEY (`identifier`) REFERENCES `users` (`identifier`) ON DELETE CASCADE,
    CONSTRAINT `fk_uc_char` FOREIGN KEY (`unique_id`)  REFERENCES `characters` (`unique_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_appearances` (
    `id`            INT UNSIGNED AUTO_INCREMENT,
    `unique_id`     VARCHAR(36)  NOT NULL,
    `skin_data`     LONGTEXT     DEFAULT NULL,
    `face_features` LONGTEXT     DEFAULT NULL,
    `tattoos`       LONGTEXT     DEFAULT NULL,
    `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_unique_id` (`unique_id`),
    CONSTRAINT `fk_appearance_char` FOREIGN KEY (`unique_id`) REFERENCES `characters` (`unique_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- NOTE (correctif P0.1) : les colonnes is_job_outfit/job_name/job_grade ci-dessous
-- ne sont plus alimentées par le code depuis l'ajout de `character_job_outfits`
-- (voir plus bas). Elles sont conservées telles quelles pour ne rien casser sur
-- les bases existantes ; leur suppression éventuelle est un nettoyage séparé,
-- volontairement non fait ici (voir le rapport d'audit, section "trouvé mais non corrigé").
CREATE TABLE IF NOT EXISTS `character_outfits` (
    `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `unique_id`     VARCHAR(36)  NOT NULL,
    `name`          VARCHAR(50)  NOT NULL,
    `components`    LONGTEXT     DEFAULT NULL,
    `props`         LONGTEXT     DEFAULT NULL,
    `is_job_outfit` TINYINT(1)   DEFAULT 0,
    `job_name`      VARCHAR(50)  DEFAULT NULL,
    `job_grade`     INT          DEFAULT 0,
    `created_at`    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_outfit_name` (`unique_id`, `name`),
    INDEX `idx_unique_id` (`unique_id`),
    INDEX `idx_job` (`job_name`, `job_grade`),
    CONSTRAINT `fk_outfit_char` FOREIGN KEY (`unique_id`) REFERENCES `characters` (`unique_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── TENUES DE MÉTIER (correctif P0.1) ────────────────────────────────────
-- Une tenue de métier n'appartient à aucun personnage précis : elle est
-- définie par (job_name, job_grade). L'ancien code l'enregistrait dans
-- `character_outfits` avec unique_id = 'system', ce qui viole la contrainte
-- `fk_outfit_char` (aucun personnage 'system' n'existe) et fait toujours
-- échouer l'INSERT. Table dédiée, sans lien vers `characters`, pour ne pas
-- mélanger les deux concepts.
CREATE TABLE IF NOT EXISTS `character_job_outfits` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job_name`   VARCHAR(50)  NOT NULL,
    `job_grade`  INT          NOT NULL DEFAULT 0,
    `name`       VARCHAR(50)  DEFAULT NULL,
    `components` LONGTEXT     DEFAULT NULL,
    `props`      LONGTEXT     DEFAULT NULL,
    `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_job_grade` (`job_name`, `job_grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- KT_CHARACTER — MIGRATION : tenues de métier dans une table dédiée
-- ============================================================
-- Contexte (P0.1) :
--   `character_outfits.unique_id` porte une FOREIGN KEY vers `characters`.
--   Le handler "kt_character:saveJobOutfit" insérait avec unique_id='system',
--   qui ne correspond à aucune ligne de `characters` : l'INSERT échoue
--   toujours avec une erreur de contrainte de clé étrangère (1452), de façon
--   silencieuse car aucun callback ne remontait l'erreur.
--
--   Une tenue de métier n'appartient pas à un personnage précis : elle est
--   définie par (job_name, job_grade). La rattacher artificiellement à un
--   personnage fictif "system" mélangeait deux concepts différents. Cette
--   migration lui donne donc sa propre table, sans lien vers `characters`.
--
-- Cette migration est additive et sûre :
--   - Aucune table existante n'est modifiée ou supprimée.
--   - Aucune donnée existante n'est perdue.
--   - `character_outfits` garde ses colonnes is_job_outfit/job_name/job_grade
--     (non supprimées ici pour rester strictement minimal — elles ne sont
--     plus utilisées par le code après cette migration, voir le rapport).
-- ============================================================

CREATE TABLE IF NOT EXISTS `character_job_outfits` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job_name`   VARCHAR(50)  NOT NULL,
    `job_grade`  INT          NOT NULL DEFAULT 0,
    `name`       VARCHAR(50)  DEFAULT NULL,
    `components` LONGTEXT     DEFAULT NULL,
    `props`      LONGTEXT     DEFAULT NULL,
    `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_job_grade` (`job_name`, `job_grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Filet de sécurité : si une ligne 'system' existait malgré tout dans
-- `character_outfits` (ex. contrainte FK désactivée manuellement à un
-- moment donné sur un serveur en production), on la récupère plutôt que
-- de la perdre, puis on la retire de l'ancienne table pour n'avoir qu'une
-- seule source de vérité pour les tenues de métier.
INSERT INTO `character_job_outfits` (`job_name`, `job_grade`, `name`, `components`, `props`, `created_at`)
SELECT `job_name`, `job_grade`, `name`, `components`, `props`, `created_at`
FROM `character_outfits`
WHERE `unique_id` = 'system' AND `is_job_outfit` = 1
ON DUPLICATE KEY UPDATE
    `name`       = VALUES(`name`),
    `components` = VALUES(`components`),
    `props`      = VALUES(`props`);

DELETE FROM `character_outfits`
WHERE `unique_id` = 'system' AND `is_job_outfit` = 1;