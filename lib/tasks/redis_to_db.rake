namespace :redis_to_db do
  desc "Sync finalized search terms and their counts from Redis to DB"
  task sync_searches: :environment do
    redis = Redis.new
    user_keys = redis.keys("seen_terms:*")

    puts "Found #{user_keys.size} users with search terms in Redis..."

    user_keys.each do |user_key|
      ip = user_key.delete_prefix("seen_terms:")
      terms = redis.hgetall(user_key)

      terms.each do |term, count_str|
        term = term.strip
        count = count_str.to_i
        next if term.blank? || count <= 0

        last_in_db = SearchQuery.where(ip_address: ip).order(created_at: :desc).first
        if last_in_db.present? && term.start_with?(last_in_db.term) && term != last_in_db.term
          if last_in_db.search_count <= 1
            last_in_db.destroy
            puts "Deleted pyramid term '#{last_in_db.term}' for #{ip} (count was 1)"
          else
            last_in_db.decrement!(:search_count)
            puts "Decremented pyramid term '#{last_in_db.term}' for #{ip} (now #{last_in_db.search_count})"
          end

          redis.hdel(user_key, last_in_db.term.downcase.strip)
        end

        existing = SearchQuery.find_by(ip_address: ip, term: term)

        if existing
          existing.increment!(:search_count, count)
          puts "Updated '#{term}' for #{ip} in DB with +#{count}"
        else
          SearchQuery.create!(
            term: term,
            ip_address: ip,
            search_count: count
          )
          puts "Inserted '#{term}' for #{ip} in DB with count #{count}"
        end

        redis.hdel(user_key, term.downcase.strip)
      end
    end

    puts "Sync complete"
  end
end
