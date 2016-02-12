desc "Download and aggregate BTG XLS files from Amazon"
task :aggregate_btg_files do
  require 'open-uri'
  require 'roo-xls'

  origin_host = 'https://images-na.ssl-images-amazon.com'
  origin_path = '/images/G/01/rainier/help/btg/'

  spreadsheets = [
    'appliances_browse_tree_guide._TTH_.xls',          # Appliances
    'arts-and-crafts_browse_tree_guide._TTH_.xls',     # Arts, Crafts & Sewing
    'automotive_browse_tree_guide._TTH_.xls',          # Automotive
    'baby-products_browse_tree_guide._TTH_.xls',       # Baby
    'beauty_browse_tree_guide._TTH_.xls',              # Beauty
    'books_browse_tree_guide.xls',                     # Books
    'cell-phones_browse_tree_guide._TTH_.xls',         # Cell Phones & Accessories
    'fashion_browse_tree_guide.xls',                   # Clothing
    'electronics_browse_tree_guide._TTH_.xls',         # Electronics
    'grocery_browse_tree_guide._TTH_.xls',             # Grocery & Gourmet Foods
    'health_browse_tree_guide._TTH_.xls',              # Health & Personal Care
    'home-kitchen_browse_tree_guide._TTH_.xls',        # Home & Kitchen
    'industrial_browse_tree_guide._TTH_.xls',          # Industrial & Scientific
    'musical-instruments_browse_tree_guide._TTH_.xls', # Musical Instruments
    'office-products_browse_tree_guide._TTH_.xls',     # Office Products
    'garden_browse_tree_guide.xls',                    # Patio, Lawn & Garden
    'pet-supplies_browse_tree_guide._TTH_.xls',        # Pet Supplies
    'software_browse_tree_guide._TTH_.xls',            # Software
    'sporting-goods_browse_tree_guide._TTH_.xls',      # Sports & Outdoors
    'home-improvement_browse_tree_guide._TTH_.xls',    # Home Improvement
    'toys-and-games_browse_tree_guide._TTH_.xls',      # Toys & Games
    'videogames_browse_tree_guide._TTH_.xls'           # Video Games
  ]

  spreadsheets.each do |xls_fname|
    uri = URI(origin_host) + origin_path + xls_fname
    xls = Roo::Spreadsheet.open(open(uri), extension: :xls)

    exported = xls.sheet(1).to_matrix(2, 1, xls.sheet(1).last_row, 3)
    exported.to_a.each { |id, path, query| puts [id.to_i, path, query] * "\t" }
  end
end
