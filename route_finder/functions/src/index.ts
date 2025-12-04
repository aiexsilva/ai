import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";
import axios from "axios";
import { OpenAI } from "openai";
import { isValidLocation } from "./utils";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();

const mapsApiKeySecret = defineSecret("GOOGLE_MAPS_API_KEY");
const openaiApiKeySecret = defineSecret("OPENAI_API_KEY");

admin.firestore().settings({
  databaseId: "production",
});

export const generateRoutePolylines = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {

    let debugLog = "";

    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: GENERATE ROUTE POLYLINES =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    dlog("Request data: " + JSON.stringify(request.data));

    const { start, end, waypoints } = request.data;

    dlog("Start: " + JSON.stringify(start));
    dlog("End: " + JSON.stringify(end));
    dlog("Waypoints: " + JSON.stringify(waypoints));

    if (!start || !end) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a start and end location.",
      );
    }


    if (!isValidLocation(start) || !isValidLocation(end)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with valid start and end locations.",
      );
    }

    try {

      dlog("Calling route service...")

      const response = await axios.post(
        "https://getroutepolyline-634529947719.europe-southwest1.run.app/get_route",
        {
          start: { lat: start.coordinates.latitude, lng: start.coordinates.longitude },
          end: { lat: end.coordinates.latitude, lng: end.coordinates.longitude },
          waypoints: waypoints?.map((w: any) => ({
            lat: w.coordinates.latitude,
            lng: w.coordinates.longitude,
          })),
        }
      );

      dlog("Route service response: " + JSON.stringify(response.data));

      dlog("===== END: GENERATE ROUTE POLYLINES =====");

      console.log(debugLog);

      return response.data;
    } catch (error: any) {
      console.error("Error calling route service:", error.message);
      if (error.response) {
        console.error("Response data:", error.response.data);
        throw new functions.https.HttpsError(
          "internal",
          `Route service error: ${JSON.stringify(error.response.data)}`
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate route."
      );
    }
  }
);

export const createRouteWithKeywords = functions.https.onCall(
  { region: "europe-southwest1", timeoutSeconds: 60, memory: "256MiB", secrets: ["GOOGLE_MAPS_API_KEY", "OPENAI_API_KEY"] },
  async (request) => {

    let debugLog = "";
    function dlog(msg: string) {
      debugLog += msg + "\n";
    }

    dlog("===== START: CREATE ROUTE WITH KEYWORDS =====");

    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
      );
    }

    const { keywords, start, radius } = request.data as { keywords: string[], start: any, radius: number };

    dlog("Keywords: " + JSON.stringify(keywords));
    dlog("Start: " + JSON.stringify(start));
    dlog("Radius: " + radius);

    if (!keywords) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with keywords.",
      );
    }

    if (!start || !isValidLocation(start)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid start location.",
      );
    }

    if (!radius || radius < 1000 || radius > 10000) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with a valid radius (1000m-10000m).",
      );
    }

    try {
      const keywordList = keywords;

      const openaiApiKey = openaiApiKeySecret.value();
      const openai = new OpenAI({
        apiKey: openaiApiKey,
      });

      const completion = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "system",
            content: "You are a travel assistant that helps users create routes based on keywords. The user sends you a list of keywords, and from the following place types, you must select all that fit into those keywords. The place types that exist are: [´car_dealer´,´car_rental´,´car_repair´,´car_wash´,´electric_vehicle_charging_station´,´gas_station´,´parking´,´rest_stop´,´corporate_office´,´farm´,´ranch´,´art_gallery´,´art_studio´,´auditorium´,´cultural_landmark´,´historical_place´,´monument´,´museum´,´performing_arts_theater´,´sculpture´,´library´,´preschool´,´primary_school´,´school´,´secondary_school´,´university´,´adventure_sports_center´,´amphitheatre´,´amusement_center´,´amusement_park´,´aquarium´,´banquet_hall´,´barbecue_area´,´botanical_garden´,´bowling_alley´,´casino´,´childrens_camp´,´comedy_club´,´community_center´,´concert_hall´,´convention_center´,´cultural_center´,´cycling_park´,´dance_hall´,´dog_park´,´event_venue´,´ferris_wheel´,´garden´,´hiking_area´,´historical_landmark´,´internet_cafe´,´karaoke´,´marina´,´movie_rental´,´movie_theater´,´national_park´,´night_club´,´observation_deck´,´off_roading_area´,´opera_house´,´park´,´philharmonic_hall´,´picnic_ground´,´planetarium´,´plaza´,´roller_coaster´,´skateboard_park´,´state_park´,´tourist_attraction´,´video_arcade´,´visitor_center´,´water_park´,´wedding_venue´,´wildlife_park´,´wildlife_refuge´,´zoo´,´public_bath´,´public_bathroom´,´stable´,´accounting´,´atm´,´bank´,´acai_shop´,´afghani_restaurant´,´african_restaurant´,´american_restaurant´,´asian_restaurant´,´bagel_shop´,´bakery´,´bar´,´bar_and_grill´,´barbecue_restaurant´,´brazilian_restaurant´,´breakfast_restaurant´,´brunch_restaurant´,´buffet_restaurant´,´cafe´,´cafeteria´,´candy_store´,´cat_cafe´,´chinese_restaurant´,´chocolate_factory´,´chocolate_shop´,´coffee_shop´,´confectionery´,´deli´,´dessert_restaurant´,´dessert_shop´,´diner´,´dog_cafe´,´donut_shop´,´fast_food_restaurant´,´fine_dining_restaurant´,´food_court´,´french_restaurant´,´greek_restaurant´,´hamburger_restaurant´,´ice_cream_shop´,´indian_restaurant´,´indonesian_restaurant´,´italian_restaurant´,´japanese_restaurant´,´juice_shop´,´korean_restaurant´,´lebanese_restaurant´,´meal_delivery´,´meal_takeaway´,´mediterranean_restaurant´,´mexican_restaurant´,´middle_eastern_restaurant´,´pizza_restaurant´,´pub´,´ramen_restaurant´,´restaurant´,´sandwich_shop´,´seafood_restaurant´,´spanish_restaurant´,´steak_house´,´sushi_restaurant´,´tea_house´,´thai_restaurant´,´turkish_restaurant´,´vegan_restaurant´,´vegetarian_restaurant´,´vietnamese_restaurant´,´wine_bar´,´administrative_area_level_1´,´administrative_area_level_2´,´country´,´locality´,´postal_code´,´school_district´,´city_hall´,´courthouse´,´embassy´,´fire_station´,´government_office´,´local_government_office´,´neighborhood_police_station´,´police´,´post_office´,´chiropractor´,´dental_clinic´,´dentist´,´doctor´,´drugstore´,´hospital´,´massage´,´medical_lab´,´pharmacy´,´physiotherapist´,´sauna´,´skin_care_clinic´,´spa´,´tanning_studio´,´wellness_center´,´yoga_studio´,´apartment_building´,´apartment_complex´,´condominium_complex´,´housing_complex´,´bed_and_breakfast´,´budget_japanese_inn´,´campground´,´camping_cabin´,´cottage´,´extended_stay_hotel´,´farmstay´,´guest_house´,´hostel´,´hotel´,´inn´,´japanese_inn´,´lodging´,´mobile_home_park´,´motel´,´private_guest_room´,´resort_hotel´,´rv_park´,´beach´,´church´,´hindu_temple´,´mosque´,´synagogue´,´astrologer´,´barber_shop´,´beautician´,´beauty_salon´,´body_art_service´,´catering_service´,´cemetery´,´child_care_agency´,´consultant´,´courier_service´,´electrician´,´florist´,´food_delivery´,´foot_care´,´funeral_home´,´hair_care´,´hair_salon´,´insurance_agency´,´laundry´,´lawyer´,´locksmith´,´makeup_artist´,´moving_company´,´nail_salon´,´painter´,´plumber´,´psychic´,´real_estate_agency´,´roofing_contractor´,´storage´,´summer_camp_organizer´,´tailor´,´telecommunications_service_provider´,´tour_agency´,´tourist_information_center´,´travel_agency´,´veterinary_care´,´asian_grocery_store´,´auto_parts_store´,´bicycle_store´,´book_store´,´butcher_shop´,´cell_phone_store´,´clothing_store´,´convenience_store´,´department_store´,´discount_store´,´electronics_store´,´food_store´,´furniture_store´,´gift_shop´,´grocery_store´,´hardware_store´,´home_goods_store´,´home_improvement_store´,´jewelry_store´,´liquor_store´,´market´,´pet_store´,´shoe_store´,´shopping_mall´,´sporting_goods_store´,´store´,´supermarket´,´warehouse_store´,´wholesaler´,´arena´,´athletic_field´,´fishing_charter´,´fishing_pond´,´fitness_center´,´golf_course´,´gym´,´ice_skating_rink´,´playground´,´ski_resort´,´sports_activity_location´,´sports_club´,´sports_coaching´,´sports_complex´,´stadium´,´swimming_pool´,´airport´,´airstrip´,´bus_station´,´bus_stop´,´ferry_terminal´,´heliport´,´international_airport´,´light_rail_station´]",
          },
          {
            role: "user",
            content: `The user sent the following keywords: ${keywordList}. Send a list of places that are adequate for those keywords in the following example format: ["car_dealer", "restaurant", "hotel"]. Do not include any other text in your response.`,
          },
        ],
      });

      dlog(`OpenAI response: ${completion.choices[0].message.content}`);

      const mapsApiKey = mapsApiKeySecret.value();

      const response = await axios.post(
        "https://places.googleapis.com/v1/places:searchNearby",
        {
          includedTypes: JSON.parse(completion.choices[0].message.content || "[]"),
          maxResultCount: 10,
          locationRestriction: {
            circle: {
              center: {
                latitude: start.coordinates.latitude,
                longitude: start.coordinates.longitude,
              },
              radius: radius,
            },
          },
        },
        {
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": mapsApiKey,
            "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location,places.photos,places.rating,places.regularOpeningHours,places.types",
          },
        }
      );

      dlog("Places API result: " + JSON.stringify(response.data));

      const places = response.data.places;

      dlog("Places: " + JSON.stringify(places));

      if (places && places.length > 0) {
        const placeNames = places.map((p: any) => p.displayName.text);
        dlog("Fetching descriptions for: " + JSON.stringify(placeNames));

        const descriptionCompletion = await openai.chat.completions.create({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: "You are a travel assistant. You will receive a list of place names. For each place, generate a short, engaging description (max 30 words) highlighting what makes it special. Return ONLY a JSON array of strings, in the exact same order as the input list. If a place is not available, return an empty string. The text must be max of 150 characters.",
            },
            {
              role: "user",
              content: JSON.stringify(placeNames),
            },
          ],
        });

        const descriptionsContent = descriptionCompletion.choices[0].message.content;
        dlog("Descriptions response: " + descriptionsContent);

        let descriptions: string[] = [];
        try {
          descriptions = JSON.parse(descriptionsContent || "[]");
        } catch (e) {
          dlog("Error parsing descriptions JSON: " + e);
        }

        if (descriptions.length === places.length) {
          for (let i = 0; i < places.length; i++) {
            places[i].summary = descriptions[i];
          }
        } else {
          dlog("Mismatch in descriptions length. Places: " + places.length + ", Descriptions: " + descriptions.length);
        }
      }

      dlog("===== END: CREATE ROUTE WITH KEYWORDS =====");

      console.log(debugLog);

      return { places };

    } catch (error: any) {
      console.error("Error calling places service:", error.message);
      if (error.response) {
        console.error("Response data:", error.response.data);
        throw new functions.https.HttpsError(
          "internal",
          `Places service error: ${JSON.stringify(error.response.data)}`
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to get places."
      );
    }
  }
);

// cd functions
// npm run lint -- --fix
// cd ..
// firebase deploy --only functions