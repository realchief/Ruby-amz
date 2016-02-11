desc "Create and push jobs to Sidekiq's server"
namespace :sidekiq do
  task create_bestsellers_jobs: :environment do
    require 'sidekiq'

    categories_with_limits = [
      [2617941011,  4000], # Arts, Crafts & Sewing
      [15684181  ,  4000], # Automotive
      [165796011 ,  3400], # Baby
      [3760911   ,  9000], # Beauty
      [502394    ,  4000], # Camera & Photo
      [7141123011,  4000], # Clothes, Shoes & Jewelry
      [16310101  ,  7000], # Grocery & Gourmet Food
      [3760901   , 14000], # Health & Personal Care
      [1055398   , 16000], # Home & Kitchen
      [16310091  ,  2000], # Industrial & Scientific
      [284507    ,  7500], # Kitchen & Dining
      [11091801  ,  4000], # Musical Instruments
      [1064954   ,  4500], # Office Products
      [2619533011,  3500], # Pet Supplies
      [3375251   ,  8000], # Sports & Outdoors
      [228013    ,  6000], # Tools & Home Improvement
      [165793011 ,  6000]  # Toys and Games
    ]

    categories_with_limits.map! do |node_id, limit|
      [node_id, limit * 1.5]
    end

    Sidekiq::Client.push_bulk(
      'queue' => 'amz_bestsellers_green',
      'class' => 'AMZBestSellers::Worker',
      'args'  => categories_with_limits,
      'retry' => false
    )
  end

  task create_products_jobs: :environment do
    require 'sidekiq'
    require_relative '../../amz_bestsellers_bot/best_seller'

    BestSeller.find_in_batches(batch_size: 1000) do |pack|
      pack.each_slice(10) do |minipack|
        Sidekiq::Client.push(
          'queue' => 'amz_products_green',
          'class' => 'AMZProducts::Worker',
          'args'  => minipack.map { |bs| bs.asin },
          'retry' => false
        )
      end
    end
  end
end
#'Arts, Crafts & Sewing', 'Automotive', 'Baby', 'Beauty', 'Camera & Photo', 'Clothes, Shoes & Jewelry', 'Health & Personal Care', 'Home & Kitchen', 'Industrial & Scientific', 'Kitchen & Dining', 'Musical Instruments', 'Office Products', 'Pet Supplies', 'Sports & Outdoors', 'Tools & Hardware', 'Toys and Games'
