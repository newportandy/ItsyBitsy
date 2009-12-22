require 'itsybitsy'

app = ItsyBitsy.build do
  helper do
    def number_of_dogs num
      "#{num}(!!!)"
    end
  end
  
  get '/' do
    "Hello from ItsyBitsy."
  end
  
  get '/:dog_count' do
    "There are #{number_of_dogs params["dog_count"]} dogs."
  end
end

run app