// Example client init for a later phase, once the mock data in www/index.html
// is replaced with real Supabase queries. Install with: npm i @supabase/supabase-js

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL'   // Project Settings > API
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'  // Project Settings > API

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Example: fetch the signed-in homeowner's project
// const { data: profile } = await supabase.from('profiles').select('*, projects(*)').single()
