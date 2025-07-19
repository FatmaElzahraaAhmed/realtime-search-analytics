class SearchQueriesController < ApplicationController
  protect_from_forgery with: :null_session

  def record
    term = params[:term].to_s.strip
    ip_address = request.remote_ip
    finalize = ActiveModel::Type::Boolean.new.cast(params[:finalize])
    return head :ok if term.blank?

    draft_key = "draft:#{ip_address}"
    last_key = "finalized:#{ip_address}"
    seen_hash_key = "seen_terms:#{ip_address}"

    if finalize
      last_draft = $redis.get(draft_key)
      return head :ok if last_draft.blank? || last_draft != term

      existing_terms = $redis.hkeys(seen_hash_key)
      if existing_terms.include?(term.downcase.strip)
        $redis.hincrby(seen_hash_key, term.downcase.strip, 1)
        $redis.set(last_key, term)
        $redis.del(draft_key)
        return head :ok
      end

      last_finalized = $redis.get(last_key)
      if last_finalized.present? && term.start_with?(last_finalized)
        $redis.hdel(seen_hash_key, last_finalized.downcase.strip)
      end

      $redis.hset(seen_hash_key, term.downcase.strip, 1)
      $redis.set(last_key, term)
      $redis.del(draft_key)
    else
      $redis.set(draft_key, term)
    end

    head :ok
  end

  def analytics
  redis = Redis.new

  @trends = Hash.new(0)
  @per_user = Hash.new { |h, k| h[k] = {} }

  user_keys = redis.keys("seen_terms:*")

  user_keys.each do |user_key|
    ip = user_key.delete_prefix("seen_terms:")
    user_terms = redis.hgetall(user_key)

    user_terms.each do |term, count|
      count = count.to_i
      @trends[term] += count
      @per_user[ip][term] ||= 0
      @per_user[ip][term] += count
    end
  end

  SearchQuery.find_each do |query|
    term = query.term
    ip = query.ip_address
    count = query.search_count.to_i

    @trends[term] += count
    @per_user[ip][term] ||= 0
    @per_user[ip][term] += count
  end
  @trends = @trends.sort_by { |_, count| -count }.to_h
end
end
