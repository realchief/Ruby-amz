desc "Create and push jobs to Sidekiq's server"
namespace :sidekiq do
  task :enqueue_stale_best_sellers, :max_age do |t, args|
    args.with_defaults(max_age: 14)

    require 'sidekiq'
    require 'mysql2'

    db = Mysql2::Client.new(
      host:         ENV['MYSQL_HOST'],
      username:     ENV['MYSQL_USER'],
      password:     ENV['MYSQL_PASS'],
      database:     ENV['MYSQL_DB'],
      read_timeout: 600
    )
    db.query('SET @@net_read_timeout = 3000')
    db.query('SET @@net_write_timeout = 6000')

    stale_before = (Time.now - 60 * 60 * 24 * args[:max_age])

    res = db.query(<<-SQL, as: :array, stream: true, cache_rows: false)
      SELECT
          id
      FROM
          browse_nodes
      WHERE
              (    crawled_at IS NULL
                OR crawled_at <= '#{stale_before.strftime('%F %T')}'
              )
          AND is_deepest = true
      ORDER BY
          crawled_at ASC
    SQL

    res.each do |id|
      Sidekiq::Client.push(
        'queue' => 'amz_best_sellers_green',
        'class' => 'AMZBestSellers::BestSellerWorker',
        'args'  => [id],
        'retry' => false
      )
    end
  end
end
