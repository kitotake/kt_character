export interface MockCharacter {
  id: number;
  unique_id: string;
  firstname: string;
  lastname: string;
  dateofbirth: string;
  gender: string;
  model: string;
  job: string;
  job_grade: number;
  health: number;
  armor: number;
}

export const mockCharacters: MockCharacter[] = [
  {
    id: 1,
    unique_id: crypto.randomUUID(),
    firstname: "Jean",
    lastname: "Dupont",
    dateofbirth: "1995-06-15",
    gender: "m",
    model: "mp_m_freemode_01",
    job: "police",
    job_grade: 3,
    health: 180,
    armor: 50,
  },
  {
    id: 2,
    unique_id: crypto.randomUUID(),
    firstname: "Marie",
    lastname: "Martin",
    dateofbirth: "1998-11-22",
    gender: "f",
    model: "mp_f_freemode_01",
    job: "unemployed",
    job_grade: 0,
    health: 200,
    armor: 0,
  },
  {
    id: 3,
    unique_id: crypto.randomUUID(),
    firstname: "Lucas",
    lastname: "Bernard",
    dateofbirth: "2000-03-09",
    gender: "m",
    model: "mp_m_freemode_01",
    job: "ambulance",
    job_grade: 2,
    health: 200,
    armor: 0,
  },
];