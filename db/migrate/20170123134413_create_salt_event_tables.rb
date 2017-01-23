# This migrations inserts the tables needed by salt's MySQL returner in our
# database.
# https://github.com/saltstack/salt/blob/2016.3/salt/returners/mysql.py
class CreateSaltEventTables < ActiveRecord::Migration[5.0]
  def up
    query = <<-'SQL'
      CREATE TABLE `jids` (
        `jid` varchar(255) NOT NULL,
        `load` mediumtext NOT NULL,
        UNIQUE KEY `jid` (`jid`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    SQL
    ActiveRecord::Base.connection.execute(query)

    query = <<-'SQL'
      CREATE TABLE `salt_returns` (
        `fun` varchar(50) NOT NULL,
        `jid` varchar(255) NOT NULL,
        `return` mediumtext NOT NULL,
        `id` varchar(255) NOT NULL,
        `success` varchar(10) NOT NULL,
        `full_ret` mediumtext NOT NULL,
        `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        KEY `id` (`id`),
        KEY `jid` (`jid`),
        KEY `fun` (`fun`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    SQL
    ActiveRecord::Base.connection.execute(query)

    query = <<-'SQL'
      CREATE TABLE `salt_events` (
      `id` BIGINT NOT NULL AUTO_INCREMENT,
      `tag` varchar(255) NOT NULL,
      `data` mediumtext NOT NULL,
      `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      `master_id` varchar(255) NOT NULL,
      PRIMARY KEY (`id`),
      KEY `tag` (`tag`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    SQL
    ActiveRecord::Base.connection.execute(query)
  end

  def down
    drop_table :jids
    drop_table :salt_events
    drop_table :salt_returns
  end
end
