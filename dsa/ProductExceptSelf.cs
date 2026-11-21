public class Solution
{
    // 5.1 — Prefix and suffix arrays.
    // Time Complexity: O(n)
    // Space Complexity: O(n) for prefix[], suffix[], and the output array.
    public int[] ProductExceptSelf(int[] nums)
    {
        int n = nums.Length;
        int[] prefix = new int[n];
        int[] suffix = new int[n];
        int[] result = new int[n];

        int product = 1;
        for (int i = 0; i < n; i++)
        {
            prefix[i] = product;
            product *= nums[i];
        }

        product = 1;
        for (int i = n - 1; i >= 0; i--)
        {
            suffix[i] = product;
            product *= nums[i];
        }

        for (int i = 0; i < n; i++)
        {
            result[i] = prefix[i] * suffix[i];
        }

        return result;
    }

    // 5.2 — Follow-up: use the output array for prefixes and a scalar suffix product.
    // Time Complexity: O(n)
    // Extra Space Complexity: O(1), excluding the output array.
    public int[] ProductExceptSelfConstantSpace(int[] nums)
    {
        int n = nums.Length;
        int[] result = new int[n];

        int prefixProduct = 1;
        for (int i = 0; i < n; i++)
        {
            result[i] = prefixProduct;
            prefixProduct *= nums[i];
        }

        int suffixProduct = 1;
        for (int i = n - 1; i >= 0; i--)
        {
            result[i] *= suffixProduct;
            suffixProduct *= nums[i];
        }

        return result;
    }
}
