mat_GUID = 'b5179c'
deckZone_GUID = 'a24b86'
tempZone_GUID = '4da8cf'
exampleUrl = 'https://raw.githubusercontent.com/holotrek/tts/main/DeckImporter/deckimporter.json'
deckDataUrl = exampleUrl
cardGuidDataMap = {}

function onLoad()
  local mat = getObjectFromGUID(mat_GUID)
  mat.createInput({
    input_function = 'urlDefined',
    label = 'Enter JSON URL',
    value = exampleUrl,
    position = { 0, 0.1, -1.5 },
    font_size = 75,
    width = 1400,
    alignment = 3 --center
  })
  mat.createButton({
    click_function = 'clearUrl',
    label = 'X',
    position = { 1.6, 0.1, -1.5 }
  })
  mat.createButton({
    click_function = 'configureDeck',
    label = 'Configure Deck',
    position = { 0, 0.1, -1 },
    width = 800
  })
end

function urlDefined(obj, player_clicker_color, input_value, selected)
  if not selected then
    deckDataUrl = input_value
  end
end

function clearUrl(obj, player_clicker_color)
  obj.editInput({
    index = 0,
    value = ''
  })
end

function configureDeck(obj, player_clicker_color)
  if deckDataUrl then
    WebRequest.get(deckDataUrl, function(request)
      if request.is_error then
        broadcastToColor('Request failed. See chat for more details.', player_clicker_color, 'Red')
        printToColor(request.error, player_clicker_color, 'Red')
      else
        local deckData = JSON.decode(request.text)
        local deck
        local deckZone = getObjectFromGUID(deckZone_GUID)
        for _, o in ipairs(deckZone.getObjects()) do
          if o.type == 'Deck' then
            deck = o
          end
        end

        if deck then
          local tempZone = getObjectFromGUID(tempZone_GUID)
          local originalDeckPosition = deck.getPosition()
          local originalDeckRotation = deck.getRotation()
          local dataIdx = 1

          for _, c in ipairs(deck.getObjects()) do
            cardGuidDataMap[c.guid] = deckData[dataIdx]
            dataIdx = dataIdx + 1
          end

          local configurePos = tempZone.getPosition()
          configurePos.y = configurePos.y + 1
          while not deck.remainder do
            deck.takeObject({
              position = configurePos,
              callback_function = labelCard,
              smooth = false,
              flip = true,
              params = { deckData = deckData[dataIdx] }
            })
          end

          if deck.remainder then
            deck.remainder.flip()
            deck.remainder.setPosition(tempZone.getPosition())
            labelCard(deck.remainder)
          end

          Wait.time(
            function()
              for _, o in ipairs(tempZone.getObjects()) do
                if o.type == 'Deck' then
                  o.setPosition(originalDeckPosition)
                  o.setRotation(originalDeckRotation)
                end
              end
              broadcastToAll('Deck successfully configured!', 'Green')
            end,
            1
          )
        end
      end
    end)
  else
    broadcastToColor('You must first enter a URL to a valid JSON file', player_clicker_color, 'Red')
  end
end

function labelCard(card)
  local cardData = cardGuidDataMap[card.getGUID()]
  if cardData then
    for k, v in pairs(cardData) do
      setProperty(card, k, v)
    end
  end
end

function setProperty(card, property, value)
  if property == 'name' then
    card.setName(value)
  elseif property == 'description' then
    card.setDescription(value)
  elseif property == 'gmNotes' then
    card.setGMNotes(value)
  elseif property == 'lua' then
    card.setLuaScript(value)
  end
end