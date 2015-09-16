desc "Create and push jobs to Sidekiq's server"
namespace :sidekiq do
  task create_jobs: :environment do
    require 'sidekiq'

    categories_with_limits = [
      [2617941011,  4000], # Arts, Crafts & Sewing
      [15684181  ,  4000], # Automotive
      [165796011 ,  3400], # Baby
      [3760911   ,  9000], # Beauty
      [502394    ,  4000], # Camera & Photo
      [7141123011,  4000], # Clothes, Shoes & Jewelry
      [3760901   , 14000], # Health & Personal Care
      [1055398   , 16000], # Home & Kitchen
      [16310091  ,  1100], # Industrial & Scientific
      [284507    ,  6800], # Kitchen & Dining
      [11091801  ,  4000], # Musical Instruments
      [1064954   ,  4500], # Office Products
      [2619533011,  3500], # Pet Supplies
      [3375251   ,  8000], # Sports & Outdoors
      [228013    ,  4000], # Tools & Hardware
      [165793011 ,  6000]  # Toys and Games
    ]

    Sidekiq::Client.push_bulk(
      'queue' => 'amz_bestsellers_green',
      'class' => 'AMZBestSellers::Worker',
      'args'  => categories_with_limits,
      'retry' => false
    )
  end
end
