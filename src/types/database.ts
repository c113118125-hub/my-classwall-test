export type Restaurant = {
  id: string;
  name: string;
  location: string;
  category: "早餐" | "午餐" | "晚餐" | "甜點" | "咖啡" | "飲料" | "其他";
  likes: number;
  created_at: string;
};

export type Review = {
  id: string;
  restaurant_id: string;
  content: string;
  created_at: string;
};
